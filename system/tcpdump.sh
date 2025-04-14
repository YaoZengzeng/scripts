#!/bin/bash

tcpdump -i any -nn tcp port $1 -vvv -w capture.pcap
