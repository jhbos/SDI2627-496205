# <h1 Eerste versie script bash om een vm aantemaken

#!/bin/bash

set -e

VMID=105
VMNAME="debian-iso"
STORAGE="vm-pool"
ISOSTORAGE="local"
ISO="debian-13.7.0-amd64-netinst.iso"
BRIDGE="vmbr0"

# Controleer of VMID al bestaat
if qm status $VMID &>/dev/null; then
    echo "error: VMID $VMID bestaat al."
    echo "Kies andre VMID."
    exit 1
fi

echo "VMID $VMID is vrij."
echo "Debian VM aanmaken..."

qm create $VMID \
    --name "$VMNAME" \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=$BRIDGE \
    --scsihw virtio-scsi-pci

echo "10 GB disk aanmaken..."

qm set $VMID \
    --scsi0 "$STORAGE:10"

echo "Debian ISO koppelen..."

qm set $VMID \
    --ide2 "$ISOSTORAGE:iso/$ISO,media=cdrom"

echo "Bootvolgorde instellen..."

qm set $VMID \
    --boot "order=ide2;scsi0"

echo "VM configuratie:"
qm config $VMID

echo ""
echo "VM $VMID is aangemaakt."
echo "Start met: qm start $VMID"