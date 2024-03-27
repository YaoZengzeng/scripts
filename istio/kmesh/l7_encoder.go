package main

import (
	"flag"
	"fmt"
	"net"
	"os"
)

func main() {
	addr := flag.String("addr", "127.0.0.1:15000", "The IP address")
	serviceAddr := flag.String("service-addr", "10.96.41.22:80", "The service IP address")

	flag.Parse()

	conn, err := net.Dial("tcp", *addr)
	if err != nil {
		fmt.Println("connect failed:", err)
		os.Exit(1)
	}
	defer conn.Close()

	tlvTypeService := 0x1
	tlvTypeEnding := 0xfe

	msg := []byte{byte(tlvTypeService), byte(len(*serviceAddr))}
	msg = append(msg, []byte(*serviceAddr)...)
	_, err = conn.Write(msg)
	if err != nil {
		fmt.Println("send tlv type service message failed:", err)
		os.Exit(1)
	}

	msg = []byte{byte(tlvTypeEnding), 0x0}
	req := "GET / HTTP/1.1\r\n" + "Host: nginx.default\r\n" + "Connection: close\r\n" + "\r\n"

	msg = append(msg, []byte(req)...)
	_, err = conn.Write(msg)
	if err != nil {
		fmt.Println("send tlv type ending message failed:", err)
		os.Exit(1)
	}

	buffer := make([]byte, 1024)
	n, err := conn.Read(buffer)
	if err != nil {
		fmt.Println("read from connection failed:", err)
		os.Exit(1)
	}

	fmt.Printf("%s\n", buffer[:n])

	conn.Close()
}
