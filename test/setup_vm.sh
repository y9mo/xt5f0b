#!/bin/bash
# WARNING: this script will destroy data on the selected disk.
# This script can be run by executing the following:
#   curl -sL https://git.io/vAoV8 | bash
set -uo pipefail

# Update the system clock
timedatectl set-ntp true

# Fetching and ranking a live mirror list for France
curl -s "https://www.archlinux.org/mirrorlist/?country=FR&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' > /etc/pacman.d/mirrorlist

DRIVE=/dev/sda
EFIPARTITION=/dev/sda1
ENCPARTITION=/dev/sda2

USER_SETUP_URL=https://raw.githubusercontent.com/y9mo/xt5f0b/master/setup_user.yml

sgdisk --zap-all $DRIVE

sgdisk --clear \
         --new=1:0:+512MiB  --typecode=1:ef00 --change-name=1:efi \
         --new=2:0:0        --typecode=2:8300 --change-name=2:cryptsystem \
           $DRIVE

# Format device
mkfs.vfat -F32 $EFIPARTITION

# Encryption
cryptsetup luksFormat $ENCPARTITION
cryptsetup luksOpen $ENCPARTITION luks

pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks

# Create all your logical volumes on the volume group
lvcreate -L 1G vg0 -n swap
lvcreate -L 10G vg0 -n root
lvcreate -l 100%FREE vg0 -n home

# Format your filesystems on each logical volume
mkfs.ext4 /dev/vg0/root
mkfs.ext4 /dev/vg0/home
mkswap /dev/vg0/swap

# Mount your filesystems
mount /dev/vg0/root /mnt
mkdir /mnt/home
mount /dev/vg0/home /mnt/home
swapon /dev/vg0/swap

mkdir /mnt/boot
mount $EFIPARTITION /mnt/boot


# Install essential packages and then some
pacstrap /mnt base base-devel linux linux-firmware neovim git openssh sudo efibootmgr intel-ucode lvm2 networkmanager zsh ansible

#
# Configure the system
#

echo 'System Configuration'

# Generate an fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Generate required locales
sed -i -e 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf

# Setup time
arch-chroot /mnt /bin/bash <<EOF
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
EOF

#
# Network conf
#

# Create the hostname file
echo 'xtbf' > /mnt/etc/hostname

echo '127.0.0.1 localhost
::1 localhost
127.0.1.1   xtbf.localdomain   xtbf' >> /mnt/etc/hosts


#
# Initramfs
#

#
# Default
# HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
#
# Move "keyboard" and "keymap" before "block"
# Add "encrypt", "lvm2" and "resume" before "filesystems"
NEW_HOOKS=$(
    sed --silent 's/^HOOKS=(\([^)]\+\))/\1/p' /mnt/etc/mkinitcpio.conf \
        | tr ' ' '\n' \
        | sed 's/^\(block\)$/keyboard\nkeymap\n\1/;s/^\(filesystems\)$/encrypt\nlvm2\nresume\n\1/;/^\(keyboard\|keymap\|encrypt\|lvm2\|resume\)$/d' \
        | tr '\n' ' '
)
# Replace old HOOKS
sed --in-place 's/^\(HOOKS=(\)[^)]\+/\1'"$NEW_HOOKS"'/' /mnt/etc/mkinitcpio.conf

# Regenerate initrd image
arch-chroot /mnt mkinitcpio -p linux

# Systemd-boot
arch-chroot /mnt /bin/bash <<EOF
bootctl --path=/boot install
EOF

echo default arch\ntimeout 5 >> /mnt/boot/loader/loader.conf

CRYPTDEVICE_UUID=$(blkid | grep $ENCPARTITION | cut -d '"' -f 2)

echo 'title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options cryptdevice=UUID='"$CRYPTDEVICE_UUID"':vg0 root=/dev/mapper/vg0-root resume=/dev/mapper/vg0-swap rw intel_pstate=no_hwp' >> /mnt/boot/loader/entries/arch.conf


arch-chroot /mnt /bin/bash <<EOF
systemctl enable NetworkManager
EOF


arch-chroot /mnt /bin/bash <<EOF
curl -LJO $USER_SETUP_URL
ansible-playbook setup_user.yml
EOF

#
# THE END
#

# Unmount all partitions
umount -R /mnt
swapoff -a
