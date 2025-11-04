#!/bin/bash

cp ss.service /etc/systemd/system/

systemctl daemon-reload

systemctl enable ss.service

systemctl start ss.service

systemctl status ss.service
