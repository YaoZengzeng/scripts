// Copyright 2015 The Gorilla WebSocket Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build ignore
// +build ignore

package main

import (
	"context"
	"flag"
	"log"
	"net/url"
	"os"
	"os/signal"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

var addr = flag.String("addr", "localhost:8080", "http service address")
var c = flag.Int("c", 1, "client connection number, default value is 1")
var t = flag.Duration("t", 10*time.Second, "client connection duration, default value is 10s")
var l = flag.Bool("l", false, "enable log output to stdout")

func main() {
	flag.Parse()
	log.SetFlags(0)

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	u := url.URL{Scheme: "ws", Host: *addr, Path: "/echo"}
	log.Printf("connecting to %s", u.String())

	launchClientConnection := func() {
		c, _, err := websocket.DefaultDialer.Dial(u.String(), nil)
		if err != nil {
			log.Fatal("dial:", err)
		}
		defer c.Close()

		done := make(chan struct{})

		go func() {
			defer close(done)
			for {
				_, message, err := c.ReadMessage()
				if err != nil {
					log.Println("read:", err)
					return
				}
				if *l {
					log.Printf("client recv: %s", message)
				}
			}
		}()

		ticker := time.NewTicker(time.Second)
		defer ticker.Stop()

		ctx, cancel := context.WithTimeout(context.Background(), *t)
		defer cancel()

		cleanup := func() {
			// Cleanly close the connection by sending a close message and then
			// waiting (with timeout) for the server to close the connection.
			err := c.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
			if err != nil {
				log.Println("write close:", err)
				return
			}
			select {
			case <-done:
			case <-time.After(time.Second):
			}
		}

		for {
			err := c.WriteMessage(websocket.TextMessage, []byte("write message from client"))
			if err != nil {
				log.Println("write:", err)
				return
			}
			select {
			case <-done:
				return
			case <-interrupt:
				log.Println("interrupt")
				cleanup()
				return
			case <-ctx.Done():
				cleanup()
				return
			default:
			}
		}
	}

	var wg sync.WaitGroup
	for i := 0; i < *c; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			launchClientConnection()
		}()
	}

	wg.Wait()
}
