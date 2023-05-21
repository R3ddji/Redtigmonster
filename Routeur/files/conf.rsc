/interface bridge
add admin-mac=A8:6A:BB:69:E7:90 auto-mac=no name=br-wan
add name=lan1-home
add name=lan2-infra
/interface ethernet
set [ find default-name=sfp-sfpplus1 ] auto-negotiation=no comment="ONT SFP" speed=2.5Gbps
/interface wireguard
add listen-port=13231 mtu=1420 name=Mikrotik-Wireguard
/interface vlan
add comment="Internet ONT" interface=sfp-sfpplus1 loop-protect-disable-time=0s loop-protect-send-interval=1s name=vlan832-internet vlan-id=832
add comment="VOD ONT" interface=sfp-sfpplus1 loop-protect-disable-time=0s loop-protect-send-interval=1s name=vlan838-vod vlan-id=838
add comment="TV ONT" interface=sfp-sfpplus1 loop-protect-disable-time=0s loop-protect-send-interval=1s name=vlan840-tv vlan-id=840
/interface list
add name=WAN
add name=LAN-HOME
add name=LAN-INFRA
add name=LAN-VPN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip dhcp-client option
add code=60 name=vendor-class-identifier value=##AUTHENTIFICATION ORANGE
add code=77 name=userclass value=##AUTHENTIFICATION ORANGE
add code=90 name=authsend value=##AUTHENTIFICATION ORANGE
/ip pool
add name=dhcp_lan_home ranges=192.168.2.1-192.168.2.250
/ip dhcp-server
add address-pool=dhcp_lan_home interface=lan1-home lease-time=1w name=LAN-HOME-DHCP
/queue interface
set sfp-sfpplus1 queue=ethernet-default
/system logging action
add bsd-syslog=yes name=rsyslogs remote=10.10.1.2 syslog-facility=syslog syslog-severity=info target=remote
/interface bridge filter
add action=set-priority chain=output dst-port=67 ip-protocol=udp log=yes log-prefix="Set CoS6 on DHCP request" mac-protocol=ip new-priority=6 out-interface=vlan832-internet passthrough=yes
/interface bridge port
add bridge=br-wan interface=vlan832-internet
add bridge=lan1-home interface=LAN-HOME
add bridge=lan2-infra interface=LAN-INFRA
/ip neighbor discovery-settings
set discover-interface-list=LAN-HOME
/interface list member
add interface=sfp-sfpplus1 list=WAN
add interface=ether2 list=LAN-HOME
add interface=ether3 list=LAN-HOME
add interface=ether4 list=LAN-HOME
add interface=ether5 list=LAN-HOME
add interface=ether6 list=LAN-HOME
add interface=ether1 list=LAN-HOME
add interface=ether7 list=LAN-INFRA
add interface=ether8 list=LAN-INFRA
add interface=Mikrotik-Wireguard list=LAN-VPN
/interface wireguard peers
add allowed-address=10.10.10.2/32 comment=monster interface=Mikrotik-Wireguard public-key="DY826ynh2Ha8DX32DU4eLzFxVbibmOQPD7C9Rvbz52A="
add allowed-address=10.10.10.1/32 comment=redbull interface=Mikrotik-Wireguard public-key="jMx0UTugJu1HR1Ze8nVSgI1eJnxt9W+YpU/VLIHE3Ec="
add allowed-address=10.10.10.3/32 comment=tiger interface=Mikrotik-Wireguard public-key="Wc8yfi03y+MkbdmmjanMma5C8i9KHXJdnjl9R6gpogk="
/ip address
add address=192.168.2.254/24 interface=lan1-home network=192.168.2.0
add address=10.10.1.14/28 interface=lan2-infra network=10.10.1.0
add address=10.10.10.6/29 interface=Mikrotik-Wireguard network=10.10.10.0
/ip dhcp-client
add disabled=yes interface=br-wan
add interface=sfp-sfpplus1
add dhcp-options=hostname,clientid,authsend,userclass,vendor-class-identifier interface=br-wan
/ip dhcp-server network
add address=192.168.2.0/24 dns-server=1.1.1.1 gateway=192.168.2.254 netmask=24
/ip dns
set allow-remote-requests=yes servers=1.1.1.1
/ip dns static
add address=192.168.2.254 name=router.lan
/ip firewall address-list
add address=192.168.2.0/24 list=support
add address=10.10.1.0/28 list=infra
add address=10.10.10.0/29 list=support
add address=0.0.0.0/8 comment="Self-Identification [RFC 3330]" list=bogons
add address=127.0.0.0/16 comment="Loopback [RFC 3330]" list=bogons
add address=169.254.0.0/16 comment="Link Local [RFC 3330]" list=bogons
add address=172.16.0.0/12 comment="Private[RFC 1918] - CLASS B" disabled=yes list=bogons
add address=192.168.0.0/16 comment="Private[RFC 1918] - CLASS C" disabled=yes list=bogons
add address=192.0.2.0/24 comment="Reserved - IANA - TestNet1" list=bogons
add address=192.88.99.0/24 comment="6to4 Relay Anycast [RFC 3068]" list=bogons
add address=198.18.0.0/15 comment="NIDB Testing" list=bogons
add address=198.51.100.0/24 comment="Reserved - IANA - TestNet2" list=bogons
add address=203.0.113.0/24 comment="Reserved - IANA - TestNet3" list=bogons
add address=10.0.0.0/8 comment="Private[RFC 1918] - CLASS A" disabled=yes list=bogons
/ip firewall filter
add action=add-src-to-address-list address-list=Syn_Flooder chain=input comment="Add Syn Flood IP to the list" connection-limit=30,32 protocol=tcp tcp-flags=syn
add action=drop chain=input comment="Drop to syn flood list" src-address-list=Syn_Flooder
add action=add-src-to-address-list address-list=Port_Scanner chain=input comment="Port Scanner Detect" log=yes protocol=tcp psd=21,3s,3,1
add action=drop chain=input comment="Drop to port scan list" src-address-list=Port_Scanner
add action=jump chain=input comment="Jump for icmp input flow" jump-target=ICMP protocol=icmp
add action=drop chain=input comment="Block all access to the winbox - except to support list" dst-port=8291 log=yes protocol=tcp src-address-list=!support
add action=jump chain=forward comment="Jump for icmp forward flow" jump-target=ICMP protocol=icmp
add action=drop chain=forward comment="Drop to bogon list" dst-address-list=bogons
add action=add-src-to-address-list address-list=spammers chain=forward comment="Add Spammers to the list" connection-limit=30,32 dst-port=25,587 limit=30/1m,0:packet protocol=tcp
add action=drop chain=forward comment="Avoid spammers action" dst-port=25,587 protocol=tcp src-address-list=spammers
add action=accept chain=input comment="allow WireGuard" dst-port=13231 protocol=udp
add action=accept chain=input comment="Full access to SUPPORT address list" src-address-list=support
add action=drop chain=input comment="near full access to infra address list" dst-address-list=support src-address-list=infra
add action=accept chain=input comment="near full access to infra address list" src-address-list=infra
add action=accept chain=input comment="Accept DNS - UDP" port=53 protocol=udp
add action=accept chain=input comment="Accept DNS - TCP" port=53 protocol=tcp
add action=accept chain=input comment="Accept to established connections" connection-state=established
add action=accept chain=input comment="Accept to related connections" connection-state=related
add action=accept chain=input comment="web server" dst-address=#ip publique reçue par orange# dst-port=80,443 protocol=tcp
add action=drop chain=input comment="Drop anything else!"
add action=accept chain=ICMP comment="Echo request - Avoiding Ping Flood" icmp-options=8:0 limit=1,5:packet protocol=icmp
add action=accept chain=ICMP comment="Echo reply" icmp-options=0:0 protocol=icmp
add action=accept chain=ICMP comment="Time Exceeded" icmp-options=11:0 protocol=icmp
add action=accept chain=ICMP comment="Destination unreachable" icmp-options=3:0-1 protocol=icmp
add action=accept chain=ICMP comment=PMTUD icmp-options=3:4 protocol=icmp
add action=drop chain=ICMP comment="Drop to the other ICMPs" protocol=icmp
add action=jump chain=output comment="Jump for icmp output" jump-target=ICMP protocol=icmp
add action=drop chain=input comment="drop ssh brute forcers" dst-port=22 protocol=tcp src-address-list=ssh_blacklist
add action=add-src-to-address-list address-list=ssh_blacklist chain=input connection-state=new dst-port=22 protocol=tcp src-address-list=ssh_stage3
add action=add-src-to-address-list address-list=ssh_stage3 chain=input connection-state=new dst-port=22 protocol=tcp src-address-list=ssh_stage2
add action=add-src-to-address-list address-list=ssh_stage2 chain=input connection-state=new dst-port=22 protocol=tcp src-address-list=ssh_stage1
add action=add-src-to-address-list address-list=ssh_stage1 chain=input connection-state=new dst-port=22 log=yes protocol=tcp
add action=drop chain=forward comment="drop ssh brute downstream" dst-port=22 protocol=tcp src-address-list=ssh_blacklist
/ip firewall nat
add action=masquerade chain=srcnat out-interface=br-wan to-addresses=0.0.0.0
add action=dst-nat chain=dstnat dst-address=#ip publique reçue par orange# dst-port=80 log=yes protocol=tcp to-addresses=10.10.1.1 to-ports=80
add action=dst-nat chain=dstnat dst-address=#ip publique reçue par orange# dst-port=443 log=yes protocol=tcp to-addresses=10.10.1.1 to-ports=443
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/ipv6 firewall address-list
add address=::/128 comment="defconf: unspecified address" list=bad_ipv6
add address=::1/128 comment="defconf: lo" list=bad_ipv6
add address=fec0::/10 comment="defconf: site-local" list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped" list=bad_ipv6
add address=::/96 comment="defconf: ipv4 compat" list=bad_ipv6
add address=100::/64 comment="defconf: discard only " list=bad_ipv6
add address=2001:db8::/32 comment="defconf: documentation" list=bad_ipv6
add address=2001:10::/28 comment="defconf: ORCHID" list=bad_ipv6
add address=3ffe::/16 comment="defconf: 6bone" list=bad_ipv6
/ipv6 firewall filter
add action=drop chain=input comment="drop everything not coming from LAN" in-interface-list=!LAN-HOME
add action=accept chain=input comment="defconf: accept established,related,untracked" connection-state=established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=invalid
add action=accept chain=input comment="defconf: accept ICMPv6" protocol=icmpv6
add action=accept chain=input comment="defconf: accept UDP traceroute" port=33434-33534 protocol=udp
add action=accept chain=input comment="defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=udp src-address=fe80::/10
add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 protocol=udp
add action=accept chain=input comment="defconf: accept ipsec AH" protocol=ipsec-ah
add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=ipsec-esp
add action=accept chain=input comment="defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
/system clock
set time-zone-name=Europe/Paris
/system logging
add action=rsyslogs topics=info
add action=rsyslogs topics=error
add action=rsyslogs topics=warning
add action=rsyslogs topics=critical
add action=rsyslogs topics=firewall
add action=rsyslogs topics=wireguard
add action=rsyslogs topics=system
add action=rsyslogs topics=account
add action=rsyslogs topics=interface
