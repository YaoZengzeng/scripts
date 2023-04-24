## 工具

### 根据指标找工具
|性能指标|工具|说明|
|----|----|----|
|文件系统空间容量、使用率以及剩余空间|df|详细文档见 info coreutils 'df invocation'|
|索引节点容量、使用量以及剩余量|df|使用-i选项|
|页缓存和可回收Slab缓存|/proc/meminfo, sar, vmstat|使用sar -r选项|
|缓冲区|/proc/meminfo, sar, vmstat|使用sar -r选项|
|目录项、索引节点以及文件系统的缓存|/proc/slabinfo, slabtop|slabtop更为直观|
|磁盘IO使用率、IOPS、吞吐量、响应时间、IO平均大小以及等待队列长度|iostat, sar, dstat|使用iostat -d -x或者sar -d选项|
|进程IO大小以及IO延迟|pidstat, iotop|使用pidstat -d选项|
|块设备IO事件跟踪|blktrace|示例：blktrace -d /dev/sda -o- | blkparse -i-|
|进程系统调用跟踪|strace|通过系统调用跟踪进程的IO|
|进程块设备IO大小跟踪|biosnoop, biotop|需要安装bcc软件包|

### 根据工具查指标
|性能工具|IO性能指标|
|----|----|
|iostat|磁盘IO使用率、IOPS、吞吐量、响应时间、IO平均大小以及等待队列长度|
|pidstat|进程IO大小以及IO延时|
|sar|磁盘IO使用率、IOPS、吞吐量以及响应时间|
|dstat|磁盘IO使用率、IOPS以及吞吐量|
|iotop|按IO大小对进程排序|
|slabtop|目录项、索引节点以及文件系统的缓存|
|/proc/slabinfo|目录项、索引节点以及文件系统的缓存|
|/proc/meminfo|页缓存和可回收Slab缓存|
|/proc/diskstats|磁盘的IOPS、吞吐量以及延时|
|/proc/pid/io|进程IOPS、IO大小以及IO延时|
|vmstat|缓存和缓冲区用量汇总|
|blktrace|跟踪块设备IO事件|
|biosnoop|跟踪进程的块设备IO大小|
|biotop|跟踪进程块IO并按IO大小排序|
|strace|跟踪进程的IO系统调用|
|perf|跟踪内核中的IO事件|
|df|磁盘空间和索引节点使用量和剩余量|
|mount|文件系统的挂载路径以及挂载参数|
|du|目录占用的磁盘空间大小|
|tune2fs|显示和设置文件系统参数|
|hdparm|显示和设置磁盘参数|

