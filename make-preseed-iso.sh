#!/bin/bash

set -e

function extract_iso() {
  echo "Extracting iso: $1..."
  mkdir isofiles
  bsdtar -C isofiles -xf "$1"
}

function add_preseed_to_initrd() {
  echo "Adding preseed.cfg to initrd..."
  chmod +w isofiles/install.amd/ -R
  gunzip isofiles/install.amd/initrd.gz
  echo preseed.cfg | cpio -H newc -o -A -F isofiles/install.amd/initrd
  gzip isofiles/install.amd/initrd
  chmod -w isofiles/install.amd/ -R
}

function make_auto_the_default_isolinux_boot_option() {
   echo "Setting 'auto' as default ISOLINUX boot entry..."
  TMP_FILE=$(mktemp --tmpdir tfile.XXXXX)
  sed 's/timeout 0/timeout 3/g' isofiles/isolinux/isolinux.cfg >$TMP_FILE
  echo "default auto" >>$TMP_FILE
  chmod +w isofiles/isolinux/isolinux.cfg
  cat $TMP_FILE >isofiles/isolinux/isolinux.cfg && rm $TMP_FILE
  chmod -w isofiles/isolinux/isolinux.cfg
}

function recompute_md5_checksum() {
  echo "Calculating new md5 checksum..."
  echo " -- You can safely ignore the warning about a 'file system loop' below"
  cd isofiles
  chmod +w md5sum.txt
  find . -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum >md5sum.txt
  chmod -w md5sum.txt
  cd ..
}

function generate_new_iso_and_cleanup() {
  echo "Generating new iso: $1..."
  chmod +w isofiles/isolinux/isolinux.bin
  genisoimage -r -J -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o "$1" \
    isofiles

  isohybrid "$1"
  chmod +w isofiles -R
  rm -rf isofiles
}

extract_iso "$1"
add_preseed_to_initrd
make_auto_the_default_isolinux_boot_option
recompute_md5_checksum
generate_new_iso_and_cleanup "./preseed-$(basename $1)"

echo DONE.
