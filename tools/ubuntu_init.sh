#/bin/bash

# allow root user to login via ssh
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

systemctl restart ssh
