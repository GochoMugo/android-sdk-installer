#!/bin/bash -e
#
# Android SDK Installer
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Gocho Mugo <mugo@forfuture.co.ke>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to
# whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall
# be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# project metadata
ASI="Android SDK Installer"
ASI_VERSION="0.0.0"


# script variables
ASI_REQUIREMENTS=("wget" "unzip" "lib32stdc++6" "lib32ncurses5" "openjdk-7-jdk" "curl" "tar")
ASI_ASSUME_YES=false
ASI_INSTALL_DIR="."
# Colors for Bash
ASI_COLOR_BLUE="\033[0;34m"
ASI_COLOR_GREEN="\033[0;32m"
ASI_COLOR_RED="\033[0;31m"
ASI_COLOR_RESET="\e[0m"
ASI_COLOR_WHITE="\033[1;37m"
ASI_NO_COLOR=false


# logs to console
#
# ${1}  message to write to console
# ${2} what color to use. 0 - info(blue), 1- success(green), 2 - error(red)
asi_log() {
  if [ ${ASI_NO_COLOR} == true ] ; then
    echo "android-sdk-installer: ${1}"
  else
    [ ${2} -eq 0 ] && local color=${ASI_COLOR_BLUE}
    [ ${2} -eq 1 ] && local color=${ASI_COLOR_GREEN}
    [ ${2} -eq 2 ] && local color=${ASI_COLOR_RED}
    echo -e "${ASI_COLOR_WHITE}android-sdk-installer: ${color}${1}${ASI_COLOR_RESET}"
  fi
}


# Check if user is root
# return: 0 - is root, 1- NOT root
asi_is_root() {
  [[ $EUID -eq 0 ]]
}


# setup machine for installation
asi_setup_machine() {
  # Prevents most errors that come from interrupted installation of packages.
  # See a real case of this error: http://askubuntu.com/questions/402326/how-to-manually-run-sudo-dpkg-configure-a
  asi_log "configuring dpkg" 0
  dpkg --configure -a
}


# mark the next phase
# ${1} -- message marking phase
asi_next_phase() {
  local DIV="\n----------------------------------------------------------------------------\n"
  echo -e "${DIV}${1}${DIV}"
}


# checks if a package is installed
# ${1} -- package name
# return 0 if installed. 1 if NOT installed.
asi_is_installed() {
  dpkg -s ${1} >/dev/null 2>&1
}


# checks all requirements have been installed
# ${1} -- requirements array
asi_check_requirements() {
  asi_log "checking requirements" 0
  declare -a reqs=${!1}
  return_code=0
  for req in ${reqs[@]}
  do
    local answer="yes"
    if ! asi_is_installed ${req} ; then
      answer="no"
      return_code=1
    fi
    echo "    \"${req}\" installed: ${answer}"
  done
  return ${return_code}
}


# install requirements
asi_install_requirements() {
  asi_log "installing requirements" 0
  apt-get install --yes ${ASI_REQUIREMENTS}
}


# prompt user
# ${1} -- message about the subject
# ${2} -- question to user
# return: 0 - Yes, 1 - No, 2 - Skip
asi_prompt_user() {
  local answer
  if [ ${ASI_ASSUME_YES} ] ; then
    echo 0
  else
    read -p "${1}
    ${2}
    [Y]es, [N]o, [S]kip: " answer
    case ${answer} in
      [Yy]* )
        echo 0 ;;
      [Nn]* )
        echo 1 ;;
      [Ss]* )
        echo 2 ;;
      * )
        asi_log "invalid answer" 2
        echo $(asi_prompt_user ${1} ${2}) ;;
    esac
  fi
}


# download the Android SDK
# adapted from: https://github.com/meteor/meteor/blob/ccfee68145720cd7761680215125f3f005d9ed30/scripts/generate-android-bundle.sh
# ${1} -- installation directory (where to install the SDK to)
asi_download_sdk() {
  local temp_dir="/tmp/ASI_sdk_temp"
  local root_url=http://dl.google.com/android/
  local package=android-sdk_r24.0.2-linux.tgz
  local installation_dir=$(readlink -f ${1})
  asi_log "downloading sdk from: ${root_url}${package}" 0
  mkdir ${temp_dir}
  cd ${temp_dir}
  curl -O ${root_url}${package}
  tar xzf ${package} > /dev/null
  rm ${package}
  mv android-sdk-linux ${installation_dir}
  cd -
}


# setups the Android SDK
# ${1} -- android sdk directory
asi_setup_sdk() {
  asi_log "setting up sdk" 0
  export ANDROID_HOME=${1}
  export PATH=${ANDROID_HOME}/tools:${PATH}
  export PATH=${ANDROID_HOME}/platform-tools:${PATH}
}


# handles the whole android installation of SDK
asi_install_sdk() {
  local sdk_dir=$(readlink -f ${ASI_INSTALL_DIR})
  asi_download_sdk ${sdk_dir}
  asi_setup_sdk ${sdk_dir}
}


# show help information
asi_show_help() {
  echo "${ASI} v${ASI_VERSION}"
  echo
  echo "Usage: ./android-sdk-installer.sh [options]"
  echo
  echo "options:"
  echo "    -d=<dir>,  --dir=<dir>          installation directory"
  echo "    -h,  --help                     show this help information"
  echo "    -nc, --no-color                 disable color output"
  echo "    -v,  --version                  show version information"
  echo "    -y,  --yes                      assume yes to all prompts"
}


# show version information
asi_show_version() {
  asi_log "${ASI} v${ASI_VERSION} by GochoMugo <mugo@forfuture.co.ke>" 0
  asi_log "Repo at https://github.com/GochoMugo/android-sdk-installer" 0
}


# process options passed to script
# adapted from: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
asi_process_script_options() {
  for i in "${1}"
  do
  case $i in
    -y|--yes )
      ASI_ASSUME_YES=true
      shift
      ;;
    -d=*|--dir=* )
      ASI_INSTALL_DIR="${i#*=}"
      shift
      ;;
    -nc|--no-color )
      ASI_NO_COLOR=true
      ;;
    -h|--help )
      asi_show_help
      exit
      ;;
    -v|--version )
      asi_show_version
      exit
      ;;
    *)
      # unknown option: just ignore
      ;;
  esac
  done
}


# START
asi_process_script_options ${@}

# setting up machine
asi_next_phase "Machine Setup"
asi_setup_machine

# checking requirements
asi_next_phase "Requirements Check"
if asi_check_requirements ASI_REQUIREMENTS[@] ; then
  asi_log "all requirements satisfied" 1
else
  response=$(asi_prompt_user "Not all requirements satisfied" "Install them?")
  if [ ${response} -eq 0 ] ; then
    asi_log "installing requirements" 0
    asi_install_requirements
  else
    asi_log "ignoring requirements. moving on!" 2
  fi
fi

# downloading sdk
asi_next_phase "Android SDK Installation"
#asi_install_sdk
