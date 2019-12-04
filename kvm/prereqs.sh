#!/bin/bash

# check all prereqs for kvm script

nsslib="/lib/x86_64-linux-gnu/libnss_libvirt_guest.so.2"

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

  # https://bugs.launchpad.net/bugs/1853074
  checkpkg libnss-libvirt
  checkfile $nsslib

  cat /etc/nsswitch.conf | egrep -q "^hosts.*libvirt_guest.*" || \
    exiterr "error: libnss-libvirt not enabled"
}

# install prereqs for kvm script

kvmprereqsinst() {

  checkreqinst virsh libvirt-clients
  checkreqinst mkfs.ext4 e2fsprogs
  checkreqinst fdisk fdisk
  checkreqinst gdisk gdisk
  checkreqinst uuidgen uuid-runtime
  checkreqinst qemu-system-x86_64 qemu-system-x86
  checkreqinst qemu-img qemu-utils

  # https://bugs.launchpad.net/bugs/1853074
  checkfileinst $nsslib libnss-libvirt
  checkfile $nsslib

  cat /etc/nsswitch.conf | egrep -q "^hosts.*libvirt_guest.*" || {
    echo "warning: changing /etc/nsswitch.conf to enable libvirt nss plugin"
    sed -i "s:^hosts.*files:hosts\:    files libvirt_guest:g" /etc/nsswitch.conf
  }

  # TODO: define default pool & network if not defined
}

# prereqs fucntion

prereqs() {

  # proxy

  if [ "$proxy" != "" ]; then
    export http_proxy=$proxy
    export https_proxy=$proxy
    export ftp_proxy=$proxy
  fi

  output="/tmp/kvm.log"
  echo > $output
  echo "info: logs at $output"

  [[ "$0" =~ kvm.sh ]] && kvmprereqs
  [[ "$0" =~ fixenv.sh ]] && kvmprereqsinst

}