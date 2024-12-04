#!/bin/bash

get_os_version()
{
  echo $(cat /etc/os-release | grep VERSION_ID| awk -F'=' '{print $2}'| sed 's/"//g')
}

get_os_name()
{
  echo $(cat /etc/os-release | grep "^NAME="| awk -F'=' '{print $2}'| sed 's/"//g')
}

os_version=$(get_os_version)
os_name=$(get_os_name)
echo "> OS $os_name:$os_version"
if command -v apt-get >/dev/null; then
  echo "> apt-get is used here"
  if [ "$os_version" == "24.04" ] && [ "$os_name" == "Ubuntu" ]; then
     ./distributions/install.Ubuntu.24.04
  else
     ./distributions/install.Ubuntu.default
  fi
elif command -v yum >/dev/null; then
  echo "> yum is used here"
  ./distributions/install.yum
else
  echo "> no support for yum or apt-get"
fi