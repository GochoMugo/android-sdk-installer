#!/usr/bin/env bash
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


# modules
msu_require "console"
msu_require "core_utils"
msu_require "format"


# script variables
ASI="Android SDK Installer"
ASI_VERSION="1.0.0"
ASI_REQUIREMENTS=("wget" "unzip" "lib32stdc++6" "lib32ncurses5" "openjdk-7-jdk" "tar" "expect")
ASI_ASSUME_YES=${ASI_ASSUME_YES:-false}
ASI_INSTALL_DIR=${ASI_INSTALL_DIR:-"."}
ASI_NO_COLOR=${ASI_NO_COLOR:-false}
ASI_PKG_NAME=${ASI_PKG_NAME:-android-sdk_r24.4.1-linux.tgz}
LOG_TITLE="android-sdk-installer"


# mark the next phase
# ${1} -- message marking phase
asi_next_phase() {
  local DIV="\n----------------------------------------------------------------------------\n"
  echo -e "${DIV}${1}${DIV}"
}


# setup machine for installation
asi_setup_machine() {
  # Prevents most errors that come from interrupted installation of packages.
  # See a real case of this error: http://askubuntu.com/questions/402326/how-to-manually-run-sudo-dpkg-configure-a
  log "configuring dpkg"
  dpkg --configure -a
}


# checks if a package is installed
# ${1} - package name
# return 0 if installed. 1 if NOT installed.
asi_is_installed() {
  dpkg -s ${1} >/dev/null 2>&1
}


# override yes-no questions with ${ASI_ASSUME_YES}
asi_ask_yes_no() {
  [ ${ASI_ASSUME_YES} == true ] && return
  yes_no "${1}"
}


# handle checking and installing requirements
# ${1} - requirements array
asi_handle_requirements() {
  log "checking and installing requirements"
  declare -a reqs=${!1}
  for req in ${reqs[@]}
  do
    if ! asi_is_installed ${req} ; then
      asi_ask_yes_no "install ${req}" && {
        apt-get install --yes ${req}
      }
    fi
  done
}


# download the Android SDK
# adapted from: https://github.com/meteor/meteor/blob/ccfee68145720cd7761680215125f3f005d9ed30/scripts/generate-android-bundle.sh
# ${1} -- installation directory (where to install the SDK to, absolute path)
asi_download_sdk() {
  local temp_dir="/tmp/ASI_sdk_temp"
  local root_url=http://dl.google.com/android/
  local package=${ASI_PKG_NAME}
  local installation_dir="${1}"

  log "downloading sdk from: ${root_url}${package}"
  mkdir -p "${temp_dir}"
  cd "${temp_dir}"
  wget ${root_url}${package}
  tar xzf ${package} > /dev/null

  log "installing sdk into: ${installation_dir}"
  mkdir -p "${installation_dir}"
  mv android-sdk-linux/* "${installation_dir}"
  cd -
}


# sets up the Android SDK
# ${1} -- android sdk directory (absolute path)
asi_setup_sdk() {
  log "creating file with environment variables"
  cat > env.sh << EOF
export ANDROID_HOME='${1}'
export PATH=\${ANDROID_HOME}/tools:\${PATH}
export PATH=\${ANDROID_HOME}/platform-tools:\${PATH}
EOF

  log "downloading script to accept licenses"
  wget https://raw.githubusercontent.com/embarkmobile/android-sdk-installer/master/accept-licenses
  chmod u+x accept-licenses
  # we have to ensure `android` is in $PATH
  export PATH=${1}/tools:${PATH}
  ./accept-licenses "android update sdk --no-ui --all --filter build-tools" "android-sdk-license-bcbbd656|intel-android-sysimage-license-1ea702d1"
}


# handles the whole android installation of SDK
asi_install_sdk() {
  local sdk_dir=$(readlink -f ${ASI_INSTALL_DIR})
  asi_download_sdk "${sdk_dir}"
  asi_setup_sdk "${sdk_dir}"

  echo
  echo "now that the SDK is installed, add the lines between '#begin'"
  echo "and '#end' to ~/.bashrc (or equivalent):"
  echo
  echo "#begin"
  cat env.sh
  echo "#end"
  echo
}


# show help information
asi_show_help() {
  echo
  echo " ${ASI} v${ASI_VERSION}"
  echo
  echo " usage: android-sdk-installer [options]"
  echo
  echo " options:"
  echo "    -d=<dir>,  --dir=<dir>          installation directory"
  echo "    -y,  --yes                      assume yes to all prompts"
  # echo "    -nc, --no-color                 disable color output"
  echo "    -h,  --help                     show this help information"
  echo "    -v,  --version                  show version information"
  echo
  echo " environment variables:"
  echo "    \${ASI_INSTALL_DIR}             installation directory [default: ${ASI_INSTALL_DIR}]"
  echo "    \${ASI_ASSUME_YES}              assume yes to prompts [default: ${ASI_ASSUME_YES}]"
  # echo "    \${ASI_NO_COLOR}                disable color output [default: ${ASI_NO_COLOR}]"
  echo "    \${ASI_PKG_NAME}                package name [default: ${ASI_PKG_NAME}]"
  echo
  echo " see https://github.com/GochoMugo/android-sdk-installer for source code,"
  echo " feature requests and bug reports"
  echo
}


# show version information
asi_show_version() {
  echo "v${ASI_VERSION}"
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


# main entry point
main() {
  asi_process_script_options ${@}

  # setting up machine
  asi_next_phase "Machine Setup"
  asi_setup_machine

  # checking requirements
  asi_next_phase "Handling Requirements"
  asi_handle_requirements ASI_REQUIREMENTS[@]

  # downloading sdk
  asi_next_phase "Android SDK Installation"
  asi_install_sdk
}
