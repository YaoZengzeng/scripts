#!/bin/bash

VERSION=1.23.0

wget https://go.dev/dl/go$VERSION.linux-amd64.tar.gz

if [ "$EUID" -eq 0 ]; then

    rm -rf /usr/local/go && tar -C /usr/local -xzf go$VERSION.linux-amd64.tar.gz

    echo "export PATH=$PATH:/usr/local/go/bin:/root/go/bin" >> /root/.bashrc

else

    rm -rf /home/$USER/go && tar -C /home/$USER -xzf go$VERSION.linux-amd64.tar.gz

    export GOROOT="/home/$USER/go"
    export GOPATH="/home/$USER/go/packages"
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

    echo "export PATH=$PATH:$GOROOT/bin:$GOPATH/bin" >> /home/$USER/.profile

fi

rm go$VERSION.linux-amd64.tar.gz
