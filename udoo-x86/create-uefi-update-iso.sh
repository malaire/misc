#!/bin/bash

# DESCRIPTION
#
#   Creates an ISO image which auto updates UEFI of UDOO X86 without requiring
#   any user action, except as needed to make UDOO X86 boot from correct device.
#
# KNOWN ISSUES
#
#   PLEASE CHECK GITHUB ISSUES BEFORE USING FOR ANY KNOWN ISSUES
#   - https://github.com/malaire/misc/issues
#
# REQUIREMENTS
#
#   This has been only tested in Debian Jessie so far.
#   Requires live-build package.
#
# USAGE
#
#   1) Run this script to create the ISO image
#
#   2) Flash created image to USB stick or SD card
#     2.1) Download Etcher from https://etcher.io/
#     2.2) Flash image to USB stick or SD card using Etcher
#
#   3) Boot from image
#     3.1) Insert the USB stick or SD card to UDOO X86
#     3.2) Start UDOO X86 (*)
#     3.3) Wait until you see message that update has finished
#     3.4) Remove the USB stick or SD card so you don't restart UEFI update
#     3.5) Restart UDOO X86 (Just power off and then power on)
#
#   (*) If UDOO X86 doesn't boot from correct device automatically, then:
#     3.2.1) After starting UDOO X86, keep pressing ESC until you get UEFI menu
#     3.2.2) In UEFI menu select "Boot Manager"
#     3.2.3) Select your USB stick or SD card from menu
#
# LICENSE
#
#   Copyright (c) 2017 Markus Laire
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

# ======================================================================
# CONFIG

ISO_NAME="uefi-update-102"

UEFI_BIOS_FILE="0B020000.102"
UEFI_ZIP_FILE="UDOOX86_B02-UEFI_Update_rel102.zip"
UEFI_ZIP_DIR="${UEFI_ZIP_FILE%.*}"
UEFI_ZIP_URL="http://download.udoo.org/files/UDOO_X86/UEFI_update/$UEFI_ZIP_FILE"

MIRROR=http://deb.debian.org/debian

# ======================================================================
# SETUP

set -e

mkdir -p uefi-update-iso/build
cd uefi-update-iso/build

lb config \
  --architectures           amd64   \
  --archive-areas           main    \
  --checksums               sha256  \
  --debian-installer        false   \
  --distribution            stretch \
  --ignore-system-defaults          \
  --memtest                 none    \
  --mirror-binary           $MIRROR \
  --mirror-bootstrap        $MIRROR \
  --security                false   \
  --updates                 false   \
  --backports               false

# add timeout to bootloader (10 seconds)
mkdir config/bootloaders
cp -r /usr/share/live/build/bootloaders/isolinux config/bootloaders
perl -pi -e 's/timeout 0/timeout 100/' \
  config/bootloaders/isolinux/isolinux.cfg

# include packages required by UEFI update
echo "gcc linux-headers-4.9.0-3-amd64 make unzip" \
  > config/package-lists/custom.list.chroot

# download UEFI update and include in ISO
mkdir -p config/includes.chroot
curl -qfL "$UEFI_ZIP_URL" -o "config/includes.chroot/$UEFI_ZIP_FILE"

# create UEFI update script
cat << EOF > config/includes.chroot/uefi-update
#!/bin/bash
echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! STARTING UEFI UPDATE !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo
WORK_DIR=\$(mktemp -d /tmp/uefi-update-XXXXXXXX)
cd \$WORK_DIR
unzip "/$UEFI_ZIP_FILE" > /dev/null
cd "$UEFI_ZIP_DIR/Linux/x64"
cp ../../Bios/* .
chmod +x bios_updater_x64.sh H2OFFTx64.sh x64/H2OFFT-Lx64
sudo ./bios_updater_x64.sh "$UEFI_BIOS_FILE"
echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!                                                        !!!"
echo "!!!                UEFI UPDATE HAS FINISHED                !!!"
echo "!!!                                                        !!!"
echo "!!! Remove USB stick or SD card before restarting UDOO X86 !!!"
echo "!!!     (Just power off and then power on to restart)      !!!"
echo "!!!                                                        !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo
EOF
chmod +x config/includes.chroot/uefi-update
sudo chown root:root config/includes.chroot/uefi-update

# run UEFI update automatically on user login
MYHOOK=config/includes.chroot/lib/live/config/9999-auto-update
mkdir -p config/includes.chroot/lib/live/config
cat << EOF > "$MYHOOK"
echo "/uefi-update" >> /home/user/.profile
EOF
chmod +x "$MYHOOK"
sudo chown root:root "$MYHOOK"

# ======================================================================
# BUILD

sudo lb build |& tee ../log.txt

# ======================================================================
# CLEANUP

cd ..
cp build/live-image-amd64.contents   "$ISO_NAME.contents"
cp build/live-image-amd64.files      "$ISO_NAME.files"
cp build/live-image-amd64.hybrid.iso "$ISO_NAME.iso"
cp build/live-image-amd64.packages   "$ISO_NAME.packages"
cp log.txt                           "$ISO_NAME.log"

sudo rm -rf build log.txt
