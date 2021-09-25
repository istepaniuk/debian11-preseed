# debian-preseed
Script and configuration for fully automated debian install

Usage:
1. Download a [debian "netinst"](https://www.debian.org/CD/netinst/) image (tested with bullseye)
2. Adapt the preseed.cfg file to your needs. (This one installs just SSH and sudo)
3. Run:
```
./make-preseed-iso.sh debian-11.0.0-amd64-netinst.iso
```
This will create a new ISO image named `preseed-debian-11.0.0-amd64-netinst.iso` that
installs debian on /dev/sda without intervention, not even a boot menu prompt.

### WARNING: This deletes stuff!

The preseed.cfg that in this repository ***erases /dev/sda completely***

    Note that you can't reliably know what disk /dev/sda really is; in some sistems
    it might be the USB device that holds the installer if you are installing from USB


Also... open the script and read what it does. I made this for myself because I'm tired of hitting
enter 40 times everytime I need to install debian.

The location of the initrd is hardcoded to 'install.amd', this needs to be changed if you are using an iso
for other than amd64.

The configuration for the boot menu options is specific to bullseye in the case of a UEFI system because grub uses the position of the entry to specify the default option.

### More on how to preseed
* https://wiki.debian.org/DebianInstaller/Preseed
* https://wiki.debian.org/DebianInstaller/Preseed/EditIso
* https://wiki.debian.org/RepackBootableISO
