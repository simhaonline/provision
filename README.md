# rafaeldtinoco/provision

## kvm and lxd being provisioned

Feel free to use these scripts and provide feedback and or merge requests.

Currently, with the way they are organized, you basically have:

|directory|reason|
|---|---|
|**examples/** | same example files to be used as reference if ever needed
|**kvm/** | the kvm provisioner
|**lxd/** | lxd templates to be used
|**tests/** | quick way to test scripts

### kvm provisioner

```
$ ~/devel/provision/kvm/kvm.sh -h
info: logs at /tmp/kvm.log
syntax: /home/rafaeldtinoco/devel/provision/kvm/kvm.sh [options]
```

|option|what it means|
|---|---|
|-c <#.cpus>|number of cpus|
|-m <mem.GB>|memory size|
|-n <vm.name>|virtual machine name|
|-t <cloudinit>|default/devel (check cloud-init/*.yaml files)|
|-i <libvirt>|vanilla/numa/... (check libvirt/*.xmlfiles)|
|-d <ubuntu.codename>|xenial/bionic/disco/eoan/focal (default: stable)|
|-u <username>|as 1000:1000 in the installed vm (default: ubuntu)|
|-l <launchpad_id>|for the ssh key import (default: rafaeldtinoco)|
|-p <proxy>|proxy for http/https/ftp|
|-r <repo.url>|url for the ubuntu mirror (default: br.archive)|
|-w|wait until cloud-init is finished (after 1st boot)|

As an example you could install a kvm guest called "example":

```
$ ~/devel/provision/kvm/kvm.sh -w -c 8 -m 4 -n example -t default -i vanilla \
    -d bionic -u rafaeldtinoco -l rafaeldtinoco \
    -p http://192.168.100.252:3128/ \
    -r http://br.archive.ubuntu.com/ubuntu

info: logs at /tmp/kvm.log
option: vcpus=8
option: ramgb=4
option: hostname=example
option: cloudinit=cloud-init/default.yaml
option: libvirt=libvirt/vanilla.xml
option: distro=bionic
option: username=rafaeldtinoco
option: launchpad_id=rafaeldtinoco
option: proxy=http://192.168.100.252:3128/
option: repository=http://br.archive.ubuntu.com/ubuntu
option: wait vm
...
mark: qcow2 image
mark: nbd connecting qcow2 image
mark: disk formatting
mark: vfat partition
mark: ext4 partition
mark: debootstraping
mark: mount {procfs,sysfs,devfs}
mark: setting hostname
mark: adjusting accounts
mark: /etc/fstab
mark: /etc/network/interfaces
mark: /etc/modules
mark: /etc/default/grub
mark: /etc/apt/sources.list
mark: update and upgrade
mark: grub setup
mark: creating vm
mark: meta-data and user-data
mark: adjust user-data
mark: cleaning things up
finish: cleaning up leftovers
mark: waiting cloud-init to complete

$ virsh list --all
 Id   Name      State
-------------------------
 1    testme    running
 2    example   running

rafaeldtinoco@work:~$ ssh example
Welcome to Ubuntu 18.04.3 LTS (GNU/Linux 4.15.0-73-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

rafaeldtinoco@example:~$ 
```

*Note: I'm resolving libvirt virtual machine names as "hosts" because libvirt-nss is being used. By running "kvm/fixenv.sh" you will make sure you're also using it.*

For this 2 options:

|option|what it means|
|---|---|
|-t <cloudinit>|default/devel (check cloud-init/*.yaml files)|
|-i <libvirt>|vanilla/numa/... (check libvirt/*.xmlfiles)|

You can copy provided examples into your definitions and use those. This gives you the capability of changing provisioned VM environment based on reproducible rules.


### lxd templates

1. edit lxd/profiles/default.yaml file
2. execute: $ lxc profile edit default < ~/devel/provision/lxd/profiles/default.yaml 
3. keep your profile always updated with the file in that directory
4. editing lxd profile outside "snap" world (like lxc profile edit does) is better (vim support)
5. create as many profiles as you want (I maintain default and devel for now)
