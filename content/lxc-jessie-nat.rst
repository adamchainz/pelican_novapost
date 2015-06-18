#########################################
NAT-ed LXC host on Debian Jessie tutorial
#########################################

:date: 2015-05-19 12:00
:tags: debian, lxc
:category: Linux
:author: Pablo Seminario
:lang: en
:slug: lxc-nat-debian-jessie

LXC_ provides a handful of CLI tools and templates on top of the kernel's
containment features. I love to use it as a replacement for VirtualBox_
particularely in CI_ because of the much lower overhead it requires to run
commands in an arbitrary, disposable system. That makes me a lot more
productive without doubt, and also made our CI_ a lot faster too !

This tutorial demonstrates how to setup a bridge interface for the containers
to connect to and share a network, and uppon completion you should be able to
create, attach, destroy containers and resolve them with a local dns server.

Requirements
============

To complete this tutorial, you need Debian Jessie with the following packages::

    apt-get install lxc dnsmasq-base bridge-utils resolvconf

Enable routing on the host
==========================

Connecting LXC_ containers on internet requires the kernel to do IP routing.
Check if your kernel with the sysctl command::

    $ sudo sysctl net.ipv4.ip_forward
    net.ipv4.ip_forward = 1

``1`` means that it's enabled. If it's not, then you can enable it by creating
a :file:`/etc/sysctl.d/40-ip-forward.conf` as such::

    net.ipv4.ip_forward = 1 

Then, reload the ``systemd-sysctl.service`` and try the above ``sysctl``
command again. If it shows ``1`` then it means that the changes are persistent
and you're good to go to the next step.

Bridge interface configuration
==============================

We want a bridge interface for our containers to connect to. Such a
:file:`/etc/network/interfaces.d/lxcbr0` enables one on Debian::

    auto lxcbr0
        iface lxcbr0 inet static
            pre-up brctl addbr lxcbr0
            post-down brctl delbr lxcbr0
            bridge_fd 0
            bridge_maxwait 0
            address 10.0.3.1
            netmask 255.255.255.0
            dns-nameserver 10.0.3.1
            dns-search local
            post-up iptables -A FORWARD -i lxcbr0 -s 10.0.3.1/24 -j ACCEPT
            post-down iptables -D FORWARD -i lxcbr0 -s 10.0.3.1/24 -j ACCEPT
            post-up iptables -A POSTROUTING -t nat -s 10.0.3.1/24 -j MASQUERADE
            post-down iptables -D POSTROUTING -t nat -s 10.0.3.1/24 -j MASQUERADE
            post-up iptables -A POSTROUTING -t mangle -p udp --dport bootpc -s 10.0.3.1/24 -j CHECKSUM --checksum-fill
            post-down iptables -D POSTROUTING -t mangle -p udp --dport bootpc -s 10.0.3.1/24 -j CHECKSUM --checksum-fill
            post-up dnsmasq --interface=lxcbr0 --conf-file=/etc/lxc/dnsmasq.conf --pid-file=/var/run/lxc-dnsmasq.pid
            post-down kill $(cat /var/run/lxc-dnsmasq.pid)

Then, start it with the ``ifup`` command as such::

    ifup lxcbr0

Check that it worked::

    $ ip link show lxcbr0
    7: lxcbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default 
        link/ether fe:02:37:4a:f5:7b brd ff:ff:ff:ff:ff:ff

Configure resolvconf on the host
================================

We're also going to need to make resolvconf check our lxc bridge before our
physical interfaces. Organnizing :file:`/etc/resolvconf/interface-order` as
such works::

    # interface-order(5)
    lo.inet6
    lo.inet
    lo.@(dnsmasq|pdnsd)
    lo.!(pdns|pdns-recursor)
    lo
    lxcbr*
    tun*
    tap*
    hso*
    em+([0-9])?(_+([0-9]))*
    p+([0-9])p+([0-9])?(_+([0-9]))*
    eth*([^.]).inet6
    eth*([^.]).ip6.@(dhclient|dhcpcd|pump|udhcpc)
    eth*([^.]).inet
    eth*([^.]).@(dhclient|dhcpcd|pump|udhcpc)
    eth*
    @(ath|wifi|wlan)*([^.]).inet6
    @(ath|wifi|wlan)*([^.]).ip6.@(dhclient|dhcpcd|pump|udhcpc)
    @(ath|wifi|wlan)*([^.]).inet
    @(ath|wifi|wlan)*([^.]).@(dhclient|dhcpcd|pump|udhcpc)
    @(ath|wifi|wlan)*
    ppp*
    *

DHCP / DNS configuration for dnsmasq
====================================

Example configuration for :file:`/etc/lxc/dnsmasq.conf`::

    interface=lxcbr0
    bind-interfaces
    domain=local,10.0.3.0/24
    dhcp-range=10.0.3.100,10.0.3.200,1h
    dhcp-option=40,local
    log-dhcp

Default configuration for LXC
=============================

LXC_ containers can be connected on the lxcbr0 bridge by default if we
configure :file:`/etc/lxc/default.conf` as such::

    lxc.network.type = veth
    lxc.network.link = lxcbr0

Conflicts with avahi-daemon
===========================

Since we're using the ``.local`` domain for LXC_ containers, we also need
avahi-daemon to leave that domain alone. We can configure
:file:`/etc/avahi/avahi-daemon.conf` as such::

    # default value which conflicts with dnsmasq
    #domain-name=local
    domain-name=.avahi

And restart the service with ``sudo systemctl restart avahi-daemon``.

Testing LXC
===========

Restart the network interfaces with ``sudo systemctl restart networking`` and
start playing with LXC_ containers::

    lxc-ls --fancy
    lxc-create --name test1 --template debian -- --release wheezy
    lxc-ls --fancy
    lxc-start --name test1 --daemon
    ping -c 1 test1.local
    lxc-destroy --force --name test1

Spawning temporary containers in RAM
====================================

Every LXC_ command takes a ``--lxcpath``/``-P`` option which is
``/var/lib/lxc`` by default. It tells LXC_ where to create the rootfs with
``lxc-create`` or where to look for with commands like ``lxc-ls``,
``lxc-info``, ``lxc-attach`` and so on.

For continuous integration, we certainly don't want to store test containers
until we fill up our disk space. However, we want builds to be as fast as
possible. Amongst the optimizations we use, here's one I'd like to share, which
is creating containers in RAM:

- mount a tmpfs somewhere, ie. ``/mnt/ram``,
- use ``-P /tmp/ram`` with ``lxc-*`` commands.

This makes LXC_ more fun and faster than ever !
