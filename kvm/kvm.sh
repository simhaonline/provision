#!/bin/bash

# bootstraps a qcow2 image using debootstrap
# feeds user-data cloud-init yaml file into it

if [ $UID -ne 0 ]; then
  sudo "$0" "$@" && exit 0 || exit 1
fi

# directories

olddir=$(pwd)
scriptdir=$(dirname $0) ; [ "$scriptdir" == "." ] && scriptdir=$(pwd)

# includes

. $scriptdir/functions.sh
. $scriptdir/prereqs.sh
. $scriptdir/usage.sh

cd /tmp

# prereqs

prereqs

# cleanup marks

clean_nbd=0
clean_qcow2=0
clean_mount=0
clean_vfat=0

# arguments

usage $@

# proxy

if [ "$proxy" != "" ]; then
  export http_proxy=$proxy
  export https_proxy=$proxy
  export ftp_proxy=$proxy
fi

# defaults

[ "$hostname" == "" ] && hostname="vmtest123"
[ "$vcpus" == "" ] && vcpus=2
[ "$ramgb" == "" ] && ramgb=2
[ "$template" == "" ] && template="default"
[ "$distro" == "" ] && distro=$(ubuntu-distro-info --stable)
[ "$launchpad_id" == "" ] && launchpad_id="rafaeldtinoco"
[ "$username" == "" ] && username="ubuntu"
[ "$repository" == "" ] && repository="http://br.archive.ubuntu.com/ubuntu"

# environmetal

network=$(virsh net-info default | grep Bridge | awk '{print $2}')
pooldir=$(virsh pool-dumpxml default | grep path | sed -E 's:</?path>::g; s:\s+::g')
qemubin=$(which qemu-system-x86_64)
newmac=$(printf '52:54:00:%02X:%02X:%02X\n' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))

# temp dirs

target=$(mktemp -d XXXXXX)   # temporary debootstrap dir
fattarget=$(mktemp -d XXXXX) # temporary user-data mount dir

targetdir="/tmp/$target"
checkdir $targetdir

fattargetdir="/tmp/$fattarget"
checkdir $fattargetdir

# find next available nbd device

nbdfound=""
for nbdavail in /dev/nbd*; do
  lsblk | grep -q "$nbdavail " || {
    nbdfound=$nbdavail
    break
  }
done

# check qcow2 existence

qcow2vol="$pooldir/$hostname-disk01.qcow2"
qcow2size=30G

[ -f $qcow2vol ] && {
  echo "error: qcow2 volume $qcow2vol already exists"
  exit 1
}

# extra packages to install during debootstrap phase

packages="locales,ifupdown"

# cleanup loopback device and mounted dirs when exiting

cleanup() {

  echo "finish: cleaning up leftovers"

  [ $clean_vfat -eq 1 ] && umount $fattargetdir
  [ $clean_mount -eq 1 ] && {
    umount $targetdir/dev/pts >/dev/null 2>&1
    umount $targetdir/dev >/dev/null 2>&1
    umount $targetdir/sys >/dev/null 2>&1
    umount $targetdir/proc >/dev/null 2>&1
    umount $targetdir
  }
  [ $clean_nbd -eq 1 ] && qemu-nbd -d $nbdfound >/dev/null 2>&1
  sync
  [ $clean_qcow2 -eq 1 ] && rm $qcow2vol

  # rm -f /tmp/vm$$.xml

  rmdir $targetdir
  rmdir $fattargetdir

  cd $olddir
}

trap cleanup EXIT

# some initial prereqs

[ "$nbdfound" == "" ] && exiterr "error: could not find an available nbd device"

echo "- qcow2 image"

checkcond qemu-img create -f qcow2 $qcow2vol $qcow2size
clean_qcow2=1
sync; sync; sync

echo "- nbd connecting qcow2 image"

checkcond qemu-nbd -n -c $nbdavail $qcow2vol
clean_nbd=1

echo "- disk formatting"

printf "n\n\n\n+10MB\n\nn\n\n\n\n\nw\ny\n" | gdisk $nbdavail > /dev/null 2>&1
sync; sync; sync

echo "- vfat partition"

checkcond mkfs.vfat -nCIDATA ${nbdavail}p1
checkcond mount -t vfat ${nbdavail}p1 $fattargetdir
clean_vfat=1

echo "- ext4 partition"

mount_opts="noatime,nodiratime,relatime,discard,errors=remount-ro"
checkcond mkfs.ext4 -LMYROOT ${nbdavail}p2
checkcond mount -o $mount_opts ${nbdavail}p2 $targetdir
clean_mount=1

# start debootstrap

echo "- debootstraping"

checkcond debootstrap \
  --components=main,restricted,universe,multiverse \
  --include="$packages" \
  $distro \
  $targetdir \
  "$repository"

echo "- mount {procfs,sysfs,devfs}"

checkcond mount -o bind /proc $targetdir/proc
checkcond mount -o bind /sys $targetdir/sys
checkcond mount -o bind /dev $targetdir/dev
checkcond mount -o bind /dev/pts $targetdir/dev/pts

echo "- setting hostname"

echo $hostname | tee $targetdir/etc/hostname > /dev/null 2>&1

echo "- adjusting accounts"

runinjail "echo en_US.UTF-8 > /etc/locale.gen"
runinjail "locale-gen en_US.UTF-8"
runinjail "passwd -d root"

echo "- /etc/fstab"

echo """## /etc/fstab
LABEL=MYROOT / ext4 noatime,nodiratime,relatime,discard,errors=remount-ro 0 1
## end of file""" | tee $targetdir/etc/fstab

echo "- /etc/network/interfaces"

echo """## /etc/network/interfaces

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

end of file""" | tee $targetdir/etc/network/interfaces

echo "- /etc/modules"

echo """## /etc/modules
virtio_balloon
virtio_blk
virtio_net
virtio_pci
virtio_ring
virtio
ext4
## end of file""" | tee $targetdir/etc/modules

echo "- /etc/default/grub"

echo """## /etc/default/grub
GRUB_DEFAULT=0
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_TIMEOUT=2
GRUB_DISTRIBUTOR=$(lsb_release -i -s 2>/dev/null || echo Debian)
GRUB_CMDLINE_LINUX_DEFAULT="\"root=/dev/vda2 console=tty0 console=ttyS0,38400n8 apparmor=0 net.ifnames=0 elevator=noop pti=off kpti=off nopcid noibrs noibpb spectre_v2=off nospec_store_bypass_disable l1tf=off\""
GRUB_CMDLINE_LINUX=\"\"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND=\"serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1\"
GRUB_DISABLE_LINUX_UUID=\"true\"
GRUB_DISABLE_RECOVERY=\"true\"
GRUB_DISABLE_OS_PROBER=\"true\"
## end of file""" | tee $targetdir/etc/default/grub

echo "- /etc/initramfs-tools/modules"

echo """## /etc/initramfs-tools/modules
virtio_balloon
virtio_blk
virtio_net
virtio_pci
virtio_ring
virtio
ext4
## end of file""" | tee $targetdir/etc/initramfs-tools/modules

echo "- /etc/apt/sources.list"

echo """## /etc/apt/sources.list
deb $repository $distro main restricted universe multiverse
deb $repository $distro-updates main restricted universe multiverse
deb $repository $distro-proposed main restricted universe multiverse
## end of file""" | tee $target/etc/apt/sources.list

echo "- update and upgrade"

prefix="DEBIAN_FRONTEND=noninteractice"

runinjail "$prefix apt-get update"
runinjail "$prefix apt-get dist-upgrade -y"
runinjail "$prefix apt-get install -y cloud-init"
runinjail "$prefix apt-get install -y grub2 linux-image-generic linux-headers-generic"
runinjail "$prefix apt-get --purge autoremove -y"
runinjail "$prefix apt-get autoclean"

echo "- grub setup"

runinjail "echo debconf debconf/priority select low | debconf-set-selections"
runinjail "echo grub2 grub2/linux_cmdline_default string \"root=/dev/vda2 console=tty0 console=ttyS0,38400n8 apparmor=0 net.ifnames=0 elevator=noop pti=off kpti=off nopcid noibrs noibpb spectre_v2=off nospec_store_bypass_disable l1tf=off\" | debconf-set-selections"
runinjail "echo grub2 grub2/linux_cmdline string | debconf-set-selections"
runinjail "echo grub-pc grub-pc/install_devices string /dev/vda | debconf-set-selections"

runinjail "$prefix dpkg-reconfigure debconf"
runinjail "$prefix dpkg-reconfigure grub2"
runinjail "$prefix dpkg-reconfigure grub-pc"

runinjail "grub-install --force ${nbdavail}"
runinjail "update-grub"

echo "- creating vm"

uuid=$(uuidgen)

export uuid=$uuid
export hostname=$hostname
export ramgb=$ramgb
export vcpus=$vcpus
export qemubin=$qemubin
export qcow2vol=$qcow2vol

cat $scriptdir/vanilla.xml | envsubst > /tmp/vm$$.xml

checkcond virsh define /tmp/vm$$.xml

echo "- meta-data and user-data"

checkcond cp $scriptdir/$template.yaml $fattargetdir/user-data

checkcond echo "\"{instance-id: $uuid)}\"" | tee "$fattargetdir/meta-data"

echo "- adjust user-data"

proxy=$(echo $proxy | sed 's/\:/\\:/g' | sed 's/\./\\./g')
repository=$(echo $repository| sed 's/\:/\\:/g' | sed 's/\./\\./g')

sed -i "s:CHANGE_USERNAME:$username:g" $fattargetdir/user-data
sed -i "s:CHANGE_LAUNCHPAD_ID:$launchpad_id:g" $fattargetdir/user-data
sed -i "s:CHANGE_PROXY:$proxy:g" $fattargetdir/user-data
sed -i "s:CHANGE_HTTP_PROXY:$proxy:g" $fattargetdir/user-data
sed -i "s:CHANGE_HTTPS_PROXY:$proxy:g" $fattargetdir/user-data
sed -i "s:CHANGE_FTP_PROXY:$proxy:g" $fattargetdir/user-data
sed -i "s:CHANGE_REPOSITORY:$repository:g" $fattargetdir/user-data

echo "- cleaning things up"

clean_mount=1
clean_vfat=1
clean_nbd=1
clean_qcow2=0

exit 0
