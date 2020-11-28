#!/usr/bin/env bash

# config-brrb.sh

# Copyright 2020 OpsResearch LLC
#
# This file is part of Backroad Raspberry.
#
# Backroad Raspberry is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Backroad Raspberry is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Backroad Raspberry.  If not, see <https://www.gnu.org/licenses/>.
##

# BASH BOILERPLATE
set -euo pipefail
IFS=$'\n\t'
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$HERE/.."
source "config.sh"
source "funct.sh"
cd "$HERE"
##

usage(){
    echo "Usage: $0 install"
    echo "Usage: $0 cfg-user <user-name>"
    exit 1
}

do_install(){
    assert_bundle_is_current "workstation"
    install_pkgs "${BRRB_DEVELOPMENT_PKGS[@]}"
    install_vscode
    install_slime
    set_metadatum .development.version "$BRRB_VERSION"
}

cfg_user(){ # ARGS: <user-name>
    run_as "$1" configure-user-emacs.sh 
}

install_vscode(){
    if is_mac; then
        brew update
        brew tap homebrew/cask
        brew cask install visual-studio-code
    elif is_pi; then
        wget -O vscode.deb "https://aka.ms/linux-armhf-deb"
        install_pkgs ./vscode.deb
        rm vscode.deb
    else
        echo "Unknown OS '$(uname)' for install_vscode !!!"
        exit 1
    fi
}

install_slime(){
    pushd "$BRRB_HOME"
    if [ -d slime ]; then
        cd slime
        sudo git pull
    else
        sudo git clone "https://github.com/slime/slime.git"
    fi 
    popd
}

if [  $# -lt 1 ]; then
    echo "Invalid number of arguments !!!"
    usage
fi 

case $1 in
    install)
        do_install
        ;;

    cfg-user)   
        if [  $# -lt 2 ]; then
            echo "Invalid number of arguments !!!"
            usage
        fi 
        cfg_user "$2"
        ;;

    *)
        echo "Invalid argument: $1"
        usage
        ;;
esac
