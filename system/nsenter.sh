#!/bin/bash

nsenter -t $1 -n /bin/bash

