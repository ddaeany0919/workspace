#!/bin/bash

SCRIPT_VERSION='V0.0.1'

# for Font Color
if [ -f ~/bin/color.sh ]; then
    source ~/bin/color.sh
fi

echo ${_COLOR_} ${_YELLOW_} "[SCRIPT VERSION] "${_WHITE_} ${SCRIPT_VERSION} ${_NO_COLOR_}
echo

INTERFACE_NAME=enp3s0
VPN_TRAFFIC_PORT=443

echo ${_COLOR_} ${_LIGHT_GREEN_} "INTERFACE_NAME : "${_WHITE_} ${SCRIPT_VERSION} ${_NO_COLOR_}
echo ${_COLOR_} ${_LIGHT_GREEN_} "VPN_TRAFFIC_PORT : "${_WHITE_} ${SCRIPT_VERSION} ${_NO_COLOR_}

# - 루프백 (loopback) 인터페이스를 사용한 루프백 트래픽을 허용
sudo iptables -A INPUT -i lo -m comment --comment "loopback-input" -j ACCEPT
sudo iptables -A OUTPUT -o lo -m comment --comment "loopback-output" -j ACCEPT

# - 트래픽과 터널 인터페이스로 나가는 트래픽을 허용
sudo iptables -I INPUT -i ${INTERFACE_NAME} -m comment --comment "Local network" -j ACCEPT
sudo iptables -I OUTPUT -o tun0 -m comment --comment "VPN network" -j ACCEPT

# - OpenVPN의 트래픽을 허용
sudo iptables -A OUTPUT -o ${INTERFACE_NAME} -p udp --dport ${VPN_TRAFFIC_PORT} -m comment --comment "OpenVPN traffic" -j ACCEPT

# - NTP/DNS/DHCP 서비스를 허용
sudo iptables -A OUTPUT -o ${INTERFACE_NAME} -p udp --dport 123 -m comment --comment "NTP service" -j ACCEPT
sudo iptables -A OUTPUT -p UDP --dport 67:68 -m comment --comment "DHCP service" -j ACCEPT
sudo iptables -A OUTPUT -o ${INTERFACE_NAME} -p udp --dport 53 -m comment --comment "DNS service" -j ACCEPT

#- 트래픽을 이더넷 인터페이스로 포워드

sudo iptables -A FORWARD -i tun0 -o ${INTERFACE_NAME} -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i ${INTERFACE_NAME} -o tun0 -m comment --comment "Local network to VPN" -j ACCEPT

# - NAT (Network Address Translation)이 VPN에서 동작하도록 POSTROUTING 테이블에서 MASQUERADE를 설정
sudo iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

