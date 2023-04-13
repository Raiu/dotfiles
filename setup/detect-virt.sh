#!/usr/bin/env sh

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

[ "$(id -u)" -ne 0 ] && _error 'this scripts needs to be run as root'

if [ -f '/.dockerenv' ] || grep -q docker /proc/1/cgroup ; then
    printf "docker\n"
fi

if [ -f /proc/user_beancounters ] ; then
    printf "openvz\n"
fi

if [ -f /proc/xen/capabilities ] || \
        [ -f /sys/hypervisor/uuid ] ; then
    printf "xen\n"
fi

if [ -f /sys/devices/virtual/dmi/id/product_name ] && \
        grep -qi "VMware" /sys/devices/virtual/dmi/id/product_name ; then
    printf "vmware\n"
fi

if [ -f /sys/devices/virtual/dmi/id/product_name ] && \
        grep -qi "VirtualBox" /sys/devices/virtual/dmi/id/product_name ; then
    printf "virtualbox\n"
fi

if dmesg | grep -qi 'kvm: disabled by bios' ; then
    printf "kvm\n"
fi

if grep -q 'kvm\|qemu' /proc/1/environ; then
    if lspci | grep -q "VGA compatible controller:.*VMware"; then
        echo "vmware"
    elif lspci | grep -q "VGA compatible controller:.*NVIDIA"; then
        echo "systemd-nspawn-nv"
    else
        echo "kvm"
    fi
fi

if [ -f '/sys/firmware/acpi/tables/MSDM' ] ; then
    printf "parallels\n"
fi

if dmesg | grep -q "Hypervisor detected"; then
    if dmesg | grep -q "Booting paravirtualized kernel"; then
        printf "xen\n"
    elif dmesg | grep -q "KVM:"; then
        printf "kvm\n"
    elif dmesg | grep -q "QEMU ACPI"; then
        printf "qemu\n"
    elif dmesg | grep -q "VMware Virtual"; then
        printf "vmware\n"
    elif dmesg | grep -q "VirtualBox"; then
        printf "virtualbox\n"
    elif dmesg | grep -q "LXC"; then
        if dmesg | grep -q "systemd-nspawn"; then
            if dmesg | grep -q "with NVIDIA GPU pass-through support"; then
                printf "systemd-nspawn-nv\n"
            elif dmesg | grep -q "secure container"; then
                printf "systemd-nspawn-secure\n"
            else
                printf "systemd-nspawn\n"
            fi
        elif dmesg | grep -q "libvirt-lxc"; then
            if dmesg | grep -q "TCG enabled"; then
                printf "lxc-libvirt-tcg\n"
            else
                printf "lxc-libvirt\n"
            fi
        else
            printf "lxc\n"
        fi
    elif dmesg | grep -q "Linux-VServer"; then
        printf "linux-vserver\n"
    elif dmesg | grep -q "FreeBSD jail"; then
        printf "jail\n"
    fi
fi


if [ -f '/run/.containerenv' ]; then
    echo "containerd"
fi

if [ -f '/proc/self/cgroup' ] && \
        grep -q "kubepods" /proc/self/cgroup ; then
    echo "kubernetes"
fi

if _exist 'lxc-info' || grep -qi lxc /proc/1/environ > /dev/null 2>&1 ; then
    if grep -qi libvirt /proc/1/environ > /dev/null 2>&1 ; then
        if grep -qi tcg /proc/1/environ > /dev/null 2>&1 ; then
            echo "lxc-libvirt-tcg"
        else
            echo "lxc-libvirt"
        fi
    else
        echo "lxc"
    fi
fi

if _exist 'lspci' ; then
    if lspci | grep -q "VGA compatible controller:.*VMware" ; then
        echo "vmware"
    elif lspci | grep -q "VGA compatible controller:.*Parallels" ; then
        echo "parallels"
    elif lspci | grep -q "VGA compatible controller:.*NVIDIA" ; then
        echo "systemd-nspawn-nv"
    fi
fi

if _exist 'dmidecode' ; then
    if dmidecode -s system-product-name | grep -q "VMware" ; then
        echo "vmware"
    elif dmidecode -s system-product-name | grep -qi "VirtualBox" ; then
        echo "oracle"
    fi
fi

if _exist 'systemctl' ; then
    if systemctl is-active --quiet systemd-nspawn@ ; then
        if systemctl show --property=ExecMainPID --value systemd-nspawn@ | \
          xargs -I{} grep -q docker /proc/{}/cgroup ; then
            echo "systemd-nspawn"
        elif systemctl show --property=ExecMainPID --value systemd-nspawn@ | \
          xargs -I{} grep -q 'secure=1' /proc/{}/environ ; then
            echo "systemd-nspawn-secure"
        else
            echo "systemd-nspawn"
        fi
    fi
fi

if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] || \
        grep -qi Microsoft /proc/version; then
    printf "wsl\n"
fi

if uname -a | grep -q "hypervisor\|virtual\|vmware\|qemu\|xen" ; then
    _virt='vm'
fi

echo 'none'