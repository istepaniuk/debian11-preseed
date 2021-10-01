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
  tmp_isolinux_cfg=$(mktemp --tmpdir isolinux.XXXXX)

  echo "Setting 'auto' as default ISOLINUX boot entry..."
  sed 's/timeout 0/timeout 3/g' isofiles/isolinux/isolinux.cfg >$tmp_isolinux_cfg
  echo "default auto" >>$tmp_isolinux_cfg
  chmod +w isofiles/isolinux/isolinux.cfg
  cat $tmp_isolinux_cfg >isofiles/isolinux/isolinux.cfg
  chmod -w isofiles/isolinux/isolinux.cfg
  rm $tmp_isolinux_cfg
}

function make_auto_the_default_grub_boot_option() {
  echo "Setting 'auto' as default GRUB boot entry..."
  chmod +w isofiles/boot/grub/grub.cfg
  # The index for the grub menus is zero-based for the
  # Root menu, but 1-based for the rest, so 2>5 is the
  # second menu (advanced options) => fifth option (auto)
  echo 'set default="2>5"' >>isofiles/boot/grub/grub.cfg
  echo "set timeout=3" >>isofiles/boot/grub/grub.cfg
  chmod -w isofiles/boot/grub/grub.cfg
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
  local orig_iso="$1"
  local new_iso="$2"

  echo "Generating new iso: $new_iso..."
  dd if="$orig_iso" bs=1 count=432 of=mbr_template.bin

  chmod +w isofiles/isolinux/isolinux.bin
  xorriso -as mkisofs -r \
    -V 'Debian AUTO amd64' \
    -o "$new_iso" \
    -J -joliet-long \
    -cache-inodes \
    -isohybrid-mbr mbr_template.bin \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -boot-load-size 4 -boot-info-table \
    -no-emul-boot -eltorito-alt-boot \
    -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    isofiles

  chmod +w isofiles -R
  rm -rf isofiles mbr_template.bin
}

orig_iso="$1"
new_iso="./preseed-$(basename $orig_iso)"

extract_iso "$orig_iso"
add_preseed_to_initrd
make_auto_the_default_isolinux_boot_option
make_auto_the_default_grub_boot_option
recompute_md5_checksum
generate_new_iso_and_cleanup "$orig_iso" "$new_iso"

echo "DONE."
