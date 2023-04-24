## 工具

### 根据指标找工具
|性能指标|工具|说明|
|----|----|----|
|吞吐量（BPS）|sar, nethogs, iftop|分别可以查找网络接口、进程以及IP地址的网络吞吐量|
|PPS|sar, /proc/net/dev|查看网络接口的PPS|
|连接数|netstat, ss|查看网络连接数|
|延迟|ping, hping3|通过ICMP、TCP等测试网络延时|
|连接数跟踪|conntrack|查看和管理连接跟踪状况|
|路由|mtr, route, traceroute|查看路由并测试链路信息|
|DNS|dig, nslookup|排查DNS解析问题|
|防火墙和NAT|iptables|配置和管理防火墙以及NAT规则|
|网卡功能|ethtool|查看和配置网络接口的功能|
|抓包|tcpdump, Wireshark|抓包分析网络流量|
|内核协议栈追踪|bcc, systemtap|动态跟踪内核协议栈的行为|


### 根据工具查指标
|性能工具|主要功能|
|----|----|
|ifconfig, ip|查看和配置网络接口|
|ss|查看网络连接数|
|sar, /proc/net/dev/sys/class/net/eth0/statistics|查看网络接口的网络收发状况|
|nethogs|查看进程的网络收发情况|
|iftop|查看IP的网络收发状况|
|ethtool|查看和配置网络接口|
|conntrack|查看和管理连接跟踪状况|
|nslookup, dig|排查DNS解析问题|
|mtr, route, traceroute|查看路由并测试链路信息|
|ping, hping3|测试网络延迟|
|tcpdump|网络抓包工具|
|Wireshark|网络抓包工具和图形界面分析工具|
|iptables|配置和管理防火墙以及NAT规则|
|perf|剖析内核协议栈的性能|
|systemtap, bcc|动态追踪内核协议栈的行为|

## TCP优化

|TCP优化方法|内核选项|参考设置|
|----|----|----|
|增大处于TIME_WAIT状态的连接数量|net.ipv4.tcp_max_tw_buckets|1048576|
|增加连接跟踪表的大小|net.netfilter.nf_conntrack_max|1048576|
|缩短处于TIME_WAIT状态的超时时间|net.ipv4.tcp_fin_timeout|15|
|缩短连接跟踪表中处于TIME_WAIT状态连接的超时时间|net.netfilter.nf_conntrack_tcp_timeout_time_wait|30|
|允许TIME_WAIT状态占用的端口还可以用到新建的连接中|net.ipv4.tcp_tw_reuse|1|
|增大本地端口号的范围|net.ipv4.ip_local_port_range|10000 65000|
|增加系统和应用程序的最大文件描述符数|fs.nr_open(系统)，systemd配置文件中的LimitNOFILE（应用程序）|1048576|
|增加半连接的最大数量|net.ipv4.tcp_max_syn_backlog|16384|
|开启SYN Cookie|net.ipv4.tcp_syncookies|1|
|缩短发送Keepalive探测包的时间间隔|net.ipv4.tcp_keepalive_intvl|30|
|减少Keepalive探测失败后通知应用程序前的重试次数|net.ipv4.tcp_keepalive_probes|3|
|缩短最后一次数据包到Keepalive探测包的间隔时间|net.ipv4.tcp_keepalive_time|600|

## tcpdump使用

### 选项
|选项|示例|说明|
|----|----|----|
|-i|tcpdump -i eth0|指定网络接口，默认是0号接口（如eth0），any表示所有接口|
|-nn|tcpdump -nn|不解析ip地址和端口号的名称|
|-c|tcpdump -c5|限制要抓取网络包的个数|
|-A|tcpdump -A|以ASCII格式显示网络包内容（不指定时只显示头部信息）|
|-w|tcpdump -w file.pcap|保存到文件中，文件名通常以.pcap为后缀|
|-e|tcpdump -e|输出链路层的头部信息|


### 过滤表达式
|表达式|示例|说明|
|----|----|----|
|host、src host、dst host|tcpdump -nn host 35.190.27.188|主机过滤|
|net、src net、dst net|tcpdump -nn net 192.168.0.0|网络过滤|
|port、port range、src port、dst port|tcpdump -nn dst port 80|端口过滤|
|ip、ip6、arp、tcp、udp、icmp|tcpdump -nn tcp|协议过滤|
|and、or、not|tcpdump -nn icmp or udp|逻辑表达式|
|tcp[tcpflags]|tcpdump -nn "tcp[tcpflags]&tcp-syn!=0"|特定状态的TCP包|