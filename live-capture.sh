#!/bin/bash
# monitor wifi interface & extract certificates from .pcap

set -e

capture_duration=15
pcap="tshark-$(date +%s).pcap"

if command -v dumpcap &>/dev/null
then :
else
    >&2 echo "[!] dumpcap: required, but not found"
    exit 1
fi

if getcap "$(command -v dumpcap)" | grep --silent cap_net_raw;
then :
else
    >&2 echo "[!] lacking capabilities, trying to setcap"
    set -x
    sudo --reset-timestamp \
        setcap cap_net_raw,cap_net_admin=ep "$(command -v dumpcap)"
    set +xe
fi

>&2 echo "[+] starting tshark in monitor mode"
>&2 echo "[!] USER: now, please try to connect to the target hotspot, within $capture_duration seconds"
>&2 echo ""

tshark --monitor-mode -w "$pcap" --autostop "duration:$capture_duration" "$@"

>&2 echo ""
if [[ ! -r "$pcap" ]]; then
    exit 1
fi

>&2 echo "## trying to extract the certificates"
python3 -m wifipem -i "$pcap"

>&2 echo ""
if ip addr | grep --color=always mon; then
    >&2 echo ""
    >&2 echo "## you may need to manually delete these monitor interfaces; e.g."
    >&2 echo ""
    >&2 echo "sudo iw dev mon0 del"
    >&2 echo ""
    >&2 echo "where mon0 is the name of the monitor interface."
fi
