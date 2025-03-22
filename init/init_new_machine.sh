#!/bin/bash

bash ../go/install.sh

bash ../rust/install.sh

source /root/.bashrc

bash ../rust/update.sh

bash ../docker/install.sh

bash ../kind/install_kind.sh

bash ../k8s/install_kubectl.sh
