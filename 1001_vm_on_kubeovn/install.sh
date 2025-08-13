#!/bin/bash

#! PROVIDER_NAME
#! SUBNET_NAME
#! VM_IMAGE_NAME
#! VM_NAME
#! DNS_SERVER

echo
echo "This script expects the following vars to be set, if any of these are blank you need to export them"
cat <<EOF

PROVIDER_NAME:     $PROVIDER_NAME
SUBNET_NAME:       $SUBNET_NAME
VM_IMAGE_NAME:     $VM_IMAGE_NAME
VM_NAME:           $VM_NAME
DNS_SERVER:        $DNS_SERVER

EOF
echo

read -p "Press Enter to continue..."

echo "Installing Network Components"
cat templates/network.yaml | envsubst | kubectl apply -f -
echo

if [ ! $? ]; then 
    echo "Something failed. Run me again or ensure your vars are set (did you set your kubeconfig context?)"
    exit -1
fi

echo "Starting VM"
cat templates/vm.yaml | envsubst | kubectl apply -f -
echo

if [ ! $? ]; then 
    echo "VM creation failed for some reason, ensure your vars are correct"
    exit -1
fi

echo "From here, you can follow the remaining validation instructions"

