#!/usr/bin/env bash

progress() {
  echo -e "\033[44m\n${1}\n\033[0m"
}

generate_files() {
  progress "Generating configuration files"
  cp ../toybox.config .config
  scripts/genconfig.sh
  export NOBUILD=1
  scripts/make.sh

  progress "Generating Android_src.mk based on configs"

  # Stolen from scripts/make.sh
  TOYFILES="`sed -n 's/^CONFIG_\([^=]*\)=.*/\1/p' .config | xargs | tr ' [A-Z]' '|[a-z]'`"
  TOYFILES="`egrep -l "TOY[(]($TOYFILES)[ ,]" toys/*/*.c`"
  LIBFILES="`ls lib/*.c`"

  echo "LOCAL_SRC_FILES := main.c \\" > Android_src.mk
  for SRC in `echo $LIBFILES $TOYFILES | sort`; do
    echo "$SRC \\" >> Android_src.mk
  done

  cp ../toybox.mk Android.mk

  if $COMMIT; then
    progress "Commit headers and Makefiles"
    git add -f generated/*.h
    git add *.mk
    git commit -m "Add generated files for ndk-build" -m "Auto generated by ndk-box-kitchen"
  fi
}

apply_patches() {
  for p in ../toybox_patches/*; do
    git am $p
  done
}

if [ ! -d toybox ]; then
  progress "Please clone toybox, checkout to desired tag, apply patches, then run this script"
  exit 1
fi

cd toybox

case "$1" in
  generate )
    [ "$2" = "--commit" ] && COMMIT=true || COMMIT=false
    generate_files
    ;;
  patch )
    apply_patches
    ;;
  * )
    echo "Usage:"
    echo "$0 patch"
    echo "   Apply patches for toybox"
    echo "$0 generate [--commit]"
    echo "   Generate Makefiles for compilation"
    ;;
esac
