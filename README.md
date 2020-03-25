# xt5f0b

## Archlinux Install

Increase font size

```shell script
$ setfont latarcyrheb-sun32
```

Retrieve and execute install script

```shell script
$ curl -sSf https://raw.githubusercontent.com/y9mo/xt5f0b/master/setup_xps.sh | sh
```

## Ansible Arch configuration playbook

First Log in as newly created user and then execute the playbook

```shell script
$ ansible-playbook --ask-become-pass playbook.yml
```

### Misc

#### Specific MacOs

Create working bootable archlinux thumbdrive

```shell script
# Identify the USB device
$ diskutil list
$ diskutil unmountDisk /dev/diskX

# USB flash installation media
$ dd if=path/to/arch.iso of=/dev/rdiskX bs=1m
```

#### Issue with Archlinux vagrant box

Guest addition where not installed

Update kernel version

```shell script
$ sudo pacman -Syy
```

Then update your linux

```shell script
$ sudo pacman -S linux
```
Reboot so new kernel loads. Then install linux-header.

```shell script
$ sudo pacman -S linux-headers
```

Or whichever kernel you want.

```shell script
$ cd /opt/VBoxGuestAdditions-*/init
$ sudo ./vboxadd setup
```
