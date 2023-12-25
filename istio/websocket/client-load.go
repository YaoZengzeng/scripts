// Copyright 2015 The Gorilla WebSocket Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build ignore
// +build ignore

package main

import (
	"flag"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

var addr = flag.String("addr", "localhost:8080", "http service address")
var listenAddr = flag.String("listenAddr", "localhost:8090", "listener address for http service")
var c = flag.Int("c", 1, "client connection number, default value is 1")
var t = flag.Duration("t", 10*time.Second, "client connection duration, default value is 10s")
var l = flag.Bool("l", false, "enable log output to stdout")
var i = flag.Duration("i", time.Second, "time interval between connection send message")
var r = flag.Bool("r", false, "enable connection rotate")

func launchClientConnection(u string, interrupt <-chan os.Signal, rotateCh <-chan int, d time.Duration) {
	c, _, err := websocket.DefaultDialer.Dial(u, nil)
	if err != nil {
		log.Fatal("dial:", err)
	}
	defer c.Close()

	done := make(chan struct{})
	trigger := make(chan struct{})

	go func() {
		defer close(done)
		for {
			_, message, err := c.ReadMessage()
			if err != nil {
				log.Println("read:", err)
				return
			}
			if *l {
				log.Printf("CLIENT RECV: %s", message)
			}
			trigger <- struct{}{}
		}
	}()

	ticker := time.NewTicker(d)

	cleanup := func() {
		// Cleanly close the connection by sending a close message and then
		// waiting (with timeout) for the server to close the connection.
		err := c.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
		if err != nil {
			log.Println("write close:", err)
			return
		}
		if *l {
			log.Printf("clean up connection")
		}

		select {
		case <-done:
		case <-time.After(time.Second):
		}
	}

	for {
		if *l {
			log.Printf("CLIENT WRITE MESSAGE")
		}
		err := c.WriteMessage(websocket.TextMessage, []byte("write message from client"))
		if err != nil {
			log.Println("write:", err)
			return
		}
		select {
		case <-done:
			return
		case <-ticker.C:
			log.Printf("Triggered! DURATION is %v", d)
			ticker.Stop()
			cleanup()
			return
		case <-interrupt:
			log.Println("interrupt")
			cleanup()
			return
		case id := <-rotateCh:
			log.Printf("ROTATE! WORKER ID IS %v", id)
			cleanup()
			return
		case <-trigger:
			if *i != 0 {
				time.Sleep(*i)
			}
		}
	}
}

type worker struct {
	rotateCh chan int
}

type client struct {
	workers []*worker

	lock sync.Mutex
}

func (cli *client) rotate(w http.ResponseWriter, r *http.Request) {
	if cli.lock.TryLock() {
		defer cli.lock.Unlock()
		// Default interval is 1s per connection.
		interval := time.Second
		p := r.URL.Query().Get("interval")
		if i, err := time.ParseDuration(p); err == nil {
			interval = i
		}
		log.Printf("***START ROTATE, INTERVAL IS %v****", interval)
		for i := 0; i <= *c; i++ {
			time.Sleep(interval)
			cli.workers[i].rotateCh <- i
		}
	}
}

func main() {
	flag.Parse()
	log.SetFlags(0)

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	u := url.URL{Scheme: "ws", Host: *addr, Path: "/echo"}
	log.Printf("connecting to %s", u.String())

	cli := &client{}

	var wg sync.WaitGroup
	for i := 0; i <= *c; i++ {
		wg.Add(1)
		rotateCh := make(chan int)
		cli.workers = append(cli.workers, &worker{rotateCh: rotateCh})
		go func() {
			defer wg.Done()
			if *r {
				for {
					launchClientConnection(u.String(), interrupt, rotateCh, *t)
				}
			} else {
				launchClientConnection(u.String(), interrupt, rotateCh, *t)
			}
		}()
	}

	if *r {
		http.HandleFunc("/rotate", cli.rotate)

		go http.ListenAndServe(*listenAddr, nil)
	}

	wg.Wait()
}
