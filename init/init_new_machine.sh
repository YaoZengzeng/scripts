#!/bin/bash

bash ../go/install.sh

bash ../rust/install.sh

bash ../git/user-config.sh

bash ../git/editor.sh

source /root/.bashrc

bash ../rust/update.sh

bash ../docker/install.sh

bash ../kind/install_kind.sh

bash ../k8s/install_kubectl.sh

bash ../tools/fix_too_many_open_files.sh
