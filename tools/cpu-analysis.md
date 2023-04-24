## 工具

### 根据指标找工具
|性能指标|工具|说明|
|----|----|----|
|平均负载|uptime, top|uptime最简单，top提供了更全的指标|
|系统整体CPU使用率|vmstat, mpstat, top, sar, /proc/stat|top, vmstat, mpstat只可以动态查看而sar还可以记录历史数据，/proc/stat是其他性能工具的数据来源|
|进程CPU使用率|top, pidstat, ps, htop, atop|top和ps可以按CPU使用率给进程排序，而pidstat只显示实际用了CPU的进程，htop和atop以不同颜色显示更直观|
|系统上下文切换|vmstat|除了上下文切换次数，还提供运行状态和不可中断状态进程的数量|
|进程上下文切换|pidstat|注意加上-w选项|
|软中断|top, /proc/softirqs, mpstat|top提供软中断CPU使用率而/proc/softirqs和mpstat提供了各种软中断在每个CPU上的运行次数|
|硬中断|vmstat, /proc/interrupts|vmstat提供总的中断次数而/proc/interrupts提供各种中断在每个CPU上运行的累计次数|
|网络|dstat, sar, tcpdump|dstat和sar提供总的网络接收和发送情况而tcpdump则是动态抓取正在进行的内核通讯|
|IO|dstat, sar|dstat和sar都提供了整个IO的整体情况|
|CPU个数|/proc/cpuinfo, lscpu|lscpu更直观|
|事件剖析|perf, execsnoop|perf可以用来分析CPU的缓存以及内核调用链，execsnoop用来监控短时进程|

### 根据工具查指标
|性能工具|CPU性能指标|
|----|----|
|uptime|平均负载|
|top|平均负载、运行队列、整体的CPU使用率以及每个进程的状态和CPU使用率|
|vmstat|系统整体的CPU使用率、上下文切换次数、中断次数、还包括处于运行和不可中断状态的进程数量|
|mpstat|每个CPU的使用率和软中断次数|
|pidstat|进程和线程的CPU使用率、中断上下文切换次数|
|/proc/softirqs|软中断类型和在每个CPU上的累计中断次数|
|/proc/interrupts|硬中断类型和在每个CPU上的累计中断次数|
|ps|每个进程的状态和CPU使用率|
|pstree|进程的父子关系|
|dstat|系统整体的CPU使用率|
|sar|系统整体的CPU使用率，包括可配置的历史数据|
|strace|进程的系统调用|
|perf|CPU性能事件剖析，如调用链分析、CPU缓存、CPU调度等|
|execsnoop|监控短时进程|


