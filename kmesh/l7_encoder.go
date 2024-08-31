package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"net"
	"os"
	"strconv"
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

	fmt.Printf("connect to %s successfully\n", *addr)

	tlvTypeService := 0x1
	tlvTypeEnding := 0xfe

	ip, portString, err := net.SplitHostPort(*serviceAddr)
	if err != nil {
		fmt.Println("invalid ip address and port:", err)
		os.Exit(1)
	}

	p, err := strconv.ParseUint(portString, 10, 16)
	if err != nil {
		fmt.Println("failed to parse port:", err)
		os.Exit(1)
	}
	var port uint16
	port = uint16(p)

	ipParsed := net.ParseIP(ip)
	if ipParsed == nil {
		fmt.Println("failed to parse ip address:", err)
		os.Exit(1)
	}

	var ipBytes net.IP
	if ipParsed.To4() != nil {
		ipBytes = ipParsed.To4()
	} else {
		ipBytes = ipParsed
	}

	portBytes := make([]byte, 2)
	binary.BigEndian.PutUint16(portBytes, port)

	lengthBytes := make([]byte, 4)
	var length uint32
	length = uint32(len(ipBytes) + len(portBytes))
	binary.BigEndian.PutUint32(lengthBytes, length)

	fmt.Printf("lengthBytes is %v\nipBytes is %v\nportBytes is %v\n", lengthBytes, []byte(ipBytes), portBytes)

	msg := []byte{byte(tlvTypeService)}
	msg = append(msg, lengthBytes...)
	msg = append(msg, ipBytes...)
	msg = append(msg, portBytes...)

	fmt.Printf("msg is %v\n", msg)
	_, err = conn.Write(msg)
	if err != nil {
		fmt.Println("send tlv type service message failed:", err)
		os.Exit(1)
	}

	msg = []byte{byte(tlvTypeEnding), 0x0, 0x0, 0x0, 0x0}
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
