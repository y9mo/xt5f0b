# xt5f0b

Install Ansible as it is the only requirement that is not pre-installed
```shell script
$ sudo pacman -Sy ansible
```

```shell script
$ curl -LJO https://github.com/y9mo/xt5f0b/archive/master.zip
```

## Ansible Arch configuration playbook

First Log in as newly created user and execute the playbook
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
```shell
$ sudo pacman -Syy
```

Then update your linux
```shell
$ sudo pacman -S linux
```
Reboot so new kernel loads. Then install linux-header.

```shell
$ sudo pacman -S linux-headers
```

Or whichever kernel you want.

```shell
$ cd /opt/VBoxGuestAdditions-*/init
$ sudo ./vboxadd setup
```
