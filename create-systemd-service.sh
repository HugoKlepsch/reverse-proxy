#!/bin/bash -e
# Create a systemd service that autostarts & manages a docker-compose instance in the current directory
# by Uli Köhler - https://techoverflow.net
# Licensed as CC0 1.0 Universal
SERVICENAME=$(basename $(pwd))

echo "Creating systemd service... /etc/systemd/system/${SERVICENAME}.service"
# Create systemd service file
cat >$SERVICENAME.service <<EOF
[Unit]
Description=$SERVICENAME
Requires=docker.service reverse-proxy-network.service
After=docker.service reverse-proxy-network.service

[Service]
Restart=always
User=root
Group=docker
WorkingDirectory=$(pwd)
# Shutdown container (if running) when unit is started
ExecStartPre=$(which docker) compose -f docker-compose.yaml down
# Start container when unit is started
ExecStart=$(which docker) compose -f docker-compose.yaml up
# Stop container when unit is stopped
ExecStop=$(which docker) compose -f docker-compose.yaml down

[Install]
WantedBy=multi-user.target
EOF

sudo cp "${SERVICENAME}.service" "/etc/systemd/system/$SERVICENAME.service"

echo "Enabling & starting $SERVICENAME"
# Autostart systemd service
sudo systemctl enable $SERVICENAME.service
# Start systemd service now
sudo systemctl start $SERVICENAME.service
