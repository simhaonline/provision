#!/bin/bash

# check all prereqs for kvm script

kvmprereqs() {

  checkreq virsh libvirt-clients
  checkreq mkfs.ext4 e2fsprogs
  checkreq fdisk fdisk
  checkreq gdisk gdisk
  checkreq uuidgen uuid-runtime
  checkreq qemu-system-x86_64 qemu-system-x86
  checkreq qemu-img qemu-utils

  checkcond virsh net-info default
  checkcond virsh pool-info default
  checkcond virsh pool-dumpxml default

}

# prereqs fucntion

prereqs() {

  output="/tmp/kvm.log"
  echo > $output

  if [[ "$0" =~ kvm.sh ]]
  then
    kvmprereqs
  fi

}

