#!/bin/bash

# exit and report error

exiterr() {
  echo $@
  exit 1
}

# check for a command existence, pointing out proper pkg

checkreq() {
  command=$1
  package=$2
  command -v $command >> $output 2>&1 || exiterr "error: package ${package} is not installed"
}

# check for a condition (any command) success

checkcond() {
  $@ >> $output 2>&1 || exiterr "error: could not run $@"
}

# check directory existence (or not)

checkdir() {
  [ -d "$1" ] || exiterr "error: directory $1 should exist"
}

checknotdir() {
  [ ! -d "$1" ] || exiterr "error: directory $1 shouldn't exist"
}

# check file existence (or not)

checkfile() {
  [ -f "$1" ] || exiterr "error: file $1 should exist"
}

checknotfile() {
  [ ! -f "$1" ] || exiterr "error: file $1 shouldn't exist"
}

# run all given cmds inside a chroot

runinjail() {
  chroot $targetdir /bin/bash -c "$1" >> $output 2>&1
}

# tee with logging

teeshush() {
  tee $@ >> $output 2>&1
}

