#!/usr/bin/env bash
#############################################################################################
##程序描述：并发测试
##实现功能：
##运行周期：
##创建作者：
##创建日期：2022-08-03
#############################################################################################


###############################
##参数设置
###############################
#路径
FWDIR="$(cd `dirname $0`;pwd)"
#引入工具类
TOOL_PATH=${FWDIR}/../utils/
. ${TOOL_PATH}/tool.func
#并发个数
thread=5
#进程号
pid=$$
#管道文件
tmp_fifofile=${FWDIR}/${pid}.fifo

fun_log 0 "[pid] ${pid}, [FWDIR] ${FWDIR}, [tmp_fifofile] ${tmp_fifofile}"

#查看当前文件描述
ls -l /proc/$$/fd

#创建管道文件
mkfifo ${tmp_fifofile}
#打开管道文件并定义为分隔符8
exec 8<> ${tmp_fifofile}
#删除管道文件，因为文件描述符打开的文件即使删除句柄也不会被释放
#rm -f ${tmp_fifofile}

#查看当前文件描述
ls -l /proc/$$/fd

#循环往管道文件中写入内容
for i in `seq ${thread}`
do
    #注意：&8等于文件描述符8，下面的命令是向文件写入回车
    echo >&8
done

for i in {1..254}
do
    #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
    read -u 8
    {
    ip=10.1.2.254
    ping -c1 -W1 ${ip} &>/dev/null
    if [[ $? -eq 0 ]]; then
        fun_log 0 "[${i}] ${ip} is up."
    else
        fun_log 0 "[${i}] ${ip} is down."
    fi
    #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
    echo >&8
    }&
done
wait
##释放文件描述符
exec 8>&-
#删除管道文件
rm -f ${tmp_fifofile}
fun_log 0 "finish..."

#查看当前文件描述
ls -l /proc/$$/fd
