#!/bin/bash

if command -v apt-get >/dev/null; then
  echo "apt-get is used here"
  ./install.Ubuntu
elif command -v yum >/dev/null; then
  echo "yum is used here"
  ./install.yum
else
  echo "no support for yum or apt-get"
fi
