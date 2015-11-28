#!/usr/bin/env bash

path_to_msu=$(which msu)

alias android-sdk-installer="sudo ${path_to_msu} run android-sdk-installer.installer.main"
alias android-sdk-installer-nonsudo="msu run android-sdk-installer.installer.main"

unset path_to_msu
