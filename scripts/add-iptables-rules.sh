#!/usr/bin/env bash

set -euo pipefail

if [[ $USER != "root" ]]; then
    >&2 echo "This script must be run with super-user privileges."
    exit 1
fi

if [[ $# -lt 1 ]]; then
    >&2 echo "Usage:   $0 <public network interface>"
    >&2 echo "Example: $0 eth0"
    >&2 echo "Check e.g. 'ip a' for your public network interface."
    exit 2
fi

ipAddr=$(ip -o -4 addr show "$1" scope global | awk '{print $4;}' | cut -d/ -f 1)
echo "Your public IP address: $ipAddr"

(
set -exuo pipefail

iptables -A FORWARD -i "$1" -o vboxnet0 -p tcp --syn -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i "$1" -o vboxnet0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i vboxnet0 -o "$1" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A PREROUTING -i "$1" -p tcp -m multiport --dports 80,443 -j DNAT --to-destination 192.168.50.10
iptables -t nat -A POSTROUTING -o vboxnet0 -j MASQUERADE

# for local connections (from vboxnet0 to 192.168.50.10)
iptables -t nat -A OUTPUT -p tcp -d "$ipAddr" -m multiport --dports 80,443 -j DNAT --to-destination 192.168.50.10
)

echo "OK"
