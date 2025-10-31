#!/bin/bash -e
# Create a systemd service that autostarts & manages a docker-compose instance in the current directory
# by Uli Köhler - https://techoverflow.net
# Licensed as CC0 1.0 Universal
# Modified by Hugo Klepsch

set -euo pipefail

SERVICENAME=$(basename $(pwd))

# Load variables
ENV_FILE=".env.bash"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE file not found." >&2
  exit 1
fi

# Use 'set -a' to export all sourced variables to the environment
set -a
if ! source "$ENV_FILE"; then
  echo "Error: Failed to source $ENV_FILE." >&2
  exit 1
fi
set +a
echo "$ENV_FILE loaded successfully."

# Create generated_config directory, where the generated unit files go before they are installed
GEN_DIR="$(pwd)/generated_config"
mkdir -p "${GEN_DIR}"
echo "Generated units are written to ${GEN_DIR}/ before installation"


service_unit_name="${SERVICENAME}.service"
echo "Creating systemd service... ${service_unit_name}"
# Create systemd service file
cat >"${GEN_DIR}/${service_unit_name}" <<EOF
[Unit]
Description=Run reverse-proxy in docker compose
After=docker.service network-online.target
Requires=docker.service network-online.target

[Service]
RestartSec=10
Restart=always
User=root
Group=docker
WorkingDirectory=$(pwd)
# Shutdown container (if running) when unit is started
ExecStartPre=/bin/bash -c ". ${ENV_FILE}; $(which docker) compose -f compose/docker-compose.yml down"
# Start container when unit is started
ExecStart=/bin/bash -c ". ${ENV_FILE}; $(which docker) compose -f compose/docker-compose.yml up --build --force-recreate"
# Stop container when unit is stopped
ExecStop=/bin/bash -c ". ${ENV_FILE}; $(which docker) compose -f compose/docker-compose.yml down"

[Install]
WantedBy=multi-user.target
EOF

if [[ "${INSTALL:-false}" == "true" ]]; then
	echo "Installing systemd service... /etc/systemd/system/${service_unit_name}"
	sudo cp "${GEN_DIR}/${service_unit_name}" "/etc/systemd/system/${service_unit_name}"

	sudo systemctl daemon-reload

	if [[ "${ENABLE_NOW:-false}" == "true" ]]; then
		# Start systemd units on startup (and right now)
		echo "Enabling & starting ${service_unit_name}"
		sudo systemctl enable --now "${service_unit_name}"
		exit 0
	else
		echo "Run with INSTALL=true ENABLE_NOW=true ./create... to install and start and enable"
		exit 0
	fi
else
	echo "Run with INSTALL=true ./create... to install"
	exit 0
fi

exit 0
