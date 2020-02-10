#!/bin/bash
# Script to run any command and throttle its network usage
# Copyright (C) 2020 Rahul Raghavan
# Permission to copy and modify is granted under the Apache license
# Modified From: https://unix.stackexchange.com/questions/328308/how-can-i-limit-download-bandwidth-of-an-existing-process-iptables-tc

set -x

function help()
{
    echo "Rate Limit: Prefix with any command to throttle network usage of the process"
    echo "\$1: rate at which to throttle (<number>[mk]bps format)"
    echo "\$2: interface to rate limit"
}

function throttle()
{
    # Create a net_cls cgroup
    cgcreate -g net_cls:slow
    # Set the class id for the cgroup
    echo 0x10001 > /sys/fs/cgroup/net_cls/slow/net_cls.classid
    # Classify packets from pid into cgroup
    cgclassify -g net_cls:slow $3
    # Rate limit packets in cgroup class
    tc qdisc add dev $2 root handle 1: htb
    tc filter add dev $2 parent 1: handle 1: cgroup
    tc class add dev $2 parent 1: classid 1:1 htb rate $1
}

rate=$1
shift

# Check format of rate
if [[ ! "$rate" =~ ^[0-9]*\.*[0-9]*[mk]bps$ ]]; then
    echo "Invalid rate: $rate -  must be in <number>[mk]bps format"
    help
    exit 1
fi

ifc=$1
shift

# Check interface exists
ip a show vmnet8 up > /dev/null 2>&1
if [[ ! $? ]]; then
    echo "Invalid interface -$ifc - does not exist or is not up"
    help
    exit
fi

# Ensure previous use of cgroup is removed
if [[ -d /sys/fs/cgroup/net_cls/slow/ ]]; then
    cgdelete net_cls:slow
fi

# Ensure previous tc settings are cleared
tc qdisc del dev "$ifc" root

# Run command in background
"$@" &
proc_id=$!

# Rate limit process
throttle "$rate" "$ifc" "$proc_id"


