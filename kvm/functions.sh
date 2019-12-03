#!/bin/bash

# check for a command existence, pointing out proper pkg

checkreq() {

  command=$1
  package=$2

  command -v $command >> $output 2>&1 || {
    echo "error: package ${package} is not installed"
    exit 1
  }

}

# check for a condition (any command) success

checkcond() {

  $@ >> $output 2>&1 || {
    echo "error: could not run $@"
    exit 1
  }

}

# check directory existence

checkdir() {

  [ -d "$1" ] || {
    echo "error: directory $1 should exist"
    exit 1
  }

}

checknotdir() {

  [ ! -d "$1" ] || {
    echo "error: directory $1 shouldn't exist"
    exit 1
  }

}

checkfile() {

  [ -f "$1" ] || {
    echo "error: file $1 should exist"
    exit 1
  }
}

# exit and report error

exiterr() {
  echo $@
  exit 1
}

# run all given cmds inside a chroot

runinjail() {
  chroot $targetdir /bin/bash -c "$1" >> $output 2>&1
}

teeshush() {
  tee $@ >> $output 2>&1
}

