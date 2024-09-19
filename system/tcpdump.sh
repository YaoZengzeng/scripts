#!/bin/bash

tcpdump -i lo -nn tcp port $1 -vvv -w capture.pcap
