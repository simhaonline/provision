#!/bin/bash

# check all arguments given to kvm script

getoptkvm() {

  vcpus=""
  ramgb=""
  hostname=""
  cloudinit=""
  username=""
  launchpad_id=""
  proxy=""

  while getopts ":c:m:n:t:d:p:l:u:r:i:h" opt; do
    # shellcheck disable=SC2220
    case ${opt} in
    c)
      vcpus=$OPTARG
      echo "option: vcpus=$vcpus"
      ;;
    m)
      ramgb=$OPTARG
      echo "option: ramgb=$ramgb"
      ;;
    n)
      hostname=$OPTARG
      echo "option: hostname=$hostname"
      ;;
    t)
      cloudinit=$OPTARG
      echo "option: cloudinit=cloud-init/$cloudinit.yaml"
      ;;
    d)
      distro=$OPTARG
      echo "option: distro=$distro"
      ;;
    p)
      proxy=$OPTARG
      echo "option: proxy=$distro"
      ;;
    l)
      launchpad_id=$OPTARG
      echo "option: launchpad_id=$launchpad_id"
      ;;
    u)
      username=$OPTARG
      echo "option: username=$username"
      ;;
    r)
      repository=$OPTARG
      echo "option: repository=$repository"
      ;;
    i)
      libvirt=$OPTARG
      echo "option: libvirt=libvirt/$libvirt.xml"
      ;;
    h)
      printf "\n"
      printf "syntax: $0 [options]\n"
      printf "\n"
      printf "options:\n"
      printf "\t-c <#.cpus>\t\t- number of cpus\n"
      printf "\t-m <mem.GB>\t\t- memory size\n"
      printf "\t-n <vm.name>\t\t- virtual machine name\n"
      printf "\t-t <cloudinit>\t\t- default/devel (check cloud-init/*.yaml files)\n"
      printf "\t-i <libvirt>\t\t- vanilla/numa/... (check libvirt/*.xmlfiles)\n"
      printf "\t-d <ubuntu.codename>\t- xenial/bionic/disco/eoan/focal (default: stable)\n"
      printf "\t-u <username>\t\t- as 1000:1000 in the installed vm (default: ubuntu)\n"
      printf "\t-l <launchpad_id>\t- for the ssh key import (default: rafaeldtinoco)\n"
      printf "\t-p <proxy>\t\t- proxy for http/https/ftp\n"
      printf "\t-r <repo.url>\t\t- url for the ubuntu mirror (default: br.archive)\n"
      printf "\n"
      exit 0
      ;;
    \?)
      echo "error: invalid option -$OPTARG" 1>&2
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [[ "$vcpus" == "" || "$ramgb" == "" || "$hostname" == "" ]]
  then
    echo "$0 -h for help"
    exit 1
  fi

  echo -n . ; sleep 1
  echo -n . ; sleep 1
  echo -n . ; sleep 1
  echo ""
}

# usage function

usage() {

  if [[ "$0" =~ kvm.sh ]]
  then
    getoptkvm $@
  fi

}
