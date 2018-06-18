#!/bin/bash

# DESCRIPTION
#
#   Updates UEFI of UDOO X86 to version 1.04
#   - see http://www.udoo.org/docs-x86/Advanced_Topics/UEFI_update.html
#
# USAGE
#
#   1) Flash Ubuntu 16.10 to USB stick
#     1.1) Download ubuntu-16.10-desktop-amd64.iso
#          from http://releases.ubuntu.com/16.10/
#     1.2) Download Etcher from https://etcher.io/
#     1.3) Flash downloaded image to USB stick using Etcher
#
#   2) Start Ubuntu on UDOO X86 without installing
#     2.1) connect USB stick to UDOO X86
#     2.2) start UDOO X86, pressing ESC several times while UDOO is starting
#     2.3) in UEFI menu select "Boot Manager"
#     2.4) select your USB stick under "EFI Boot Devices"
#          (NOT under "Legacy USB")
#     2.5) from GRUB menu select "Try Ubuntu without installing"
#     2.6) wait until Ubuntu starts
#
#   3) Update UEFI
#     3.1) click top-left icon of desktop
#     3.2) write "terminal" to search-field and start Terminal
#     3.3) write following command to Terminal:
#
#       curl -qfL https://iet.fi/misc/udoo-x86-uefi-update-104 | sudo bash
#   
# LICENSE
#
#   Copyright (c) 2017-2018 Markus Laire
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to
#   deal in the Software without restriction, including without limitation the
#   rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
#   sell copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
#   IN THE SOFTWARE.

set -e

ZIPFILE="UDOOX86_B02-UEFI_Update_rel104.zip"
BIOSFILE="0B020000.104"
URL="http://download.udoo.org/files/UDOO_X86/UEFI_update/$ZIPFILE"
DIR=$(mktemp -d /tmp/uefi-update-XXXXXXXX)

cd $DIR

echo
echo "Downloading UEFI update ..."
echo

curl -qfL "$URL" -o "$ZIPFILE"

echo
echo "Preparing for UEFI update ..."
echo

unzip "$ZIPFILE"
cd "Linux/x64"
cp ../../Bios/* .
chmod +x bios_updater_x64.sh H2OFFTx64.sh x64/H2OFFT-Lx64

echo
echo "Updating ..."
echo

sudo ./bios_updater_x64.sh "$BIOSFILE"

# cleanup
cd
rm -rf "$DIR"
