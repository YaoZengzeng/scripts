package main

import (
	"fmt"
	"net"
	"os"
)

func main() {
	serverAddr := "127.0.0.1:12345"

	// 建立 TCP 连接
	conn, err := net.Dial("tcp", serverAddr)
	if err != nil {
		fmt.Println("无法连接到服务器:", err)
		os.Exit(1)
	}
	defer conn.Close()

	msg := []byte{0x1, 0xf}
	_, err = conn.Write(msg)
	if err != nil {
		fmt.Println("send message failed:", err)
		os.Exit(1)
	}
}
