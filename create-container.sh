#!/bin/bash

set -euo pipefail

# Configuratie
CTID=200
HOSTNAME="testcontainer"
STORAGE="vm-pool"                 
DISK_SIZE="8"                     # GB
MEMORY="1024"                     # MB
CORES="2"
BRIDGE="vmbr0"
TEMPLATE="local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst"
ROOT_PASSWORD="root123"
ipaddress="dhcp"  # of statisch: 192.168.1.50/24

# controleer CTID vrij?

if pct status "${CTID}" &>/dev/null; then
    echo "Container ID ${CTID} bestaat al. Kies een andere CTID."
    exit 1
fi


#Container aanmaken

echo "Container ${CTID} aanmaken op '${STORAGE}'..."

pct create "${CTID}" "${TEMPLATE}" \
    --hostname "${HOSTNAME}" \
    --rootfs "${STORAGE}:${DISK_SIZE}" \
    --memory "${MEMORY}" \
    --cores "${CORES}" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=${ipaddress}" \
    --unprivileged 1 \
    --features nesting=1 \
    --password "${ROOT_PASSWORD}" \
    --start 1


# Info

echo ""
echo "Container ${CTID} draait!"
echo ""
echo "  Console openen: pct enter ${CTID}"
