#!/usr/bin/env bash
######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：2024-12-10
##修改内容：并发测试
##修改人员：cqx
#####################################################


######################################################################
##参数设置
######################################################################
##判断系统是windows还是Linux
system_name=`uname`
##路径
FWDIR="$(cd `dirname $0`;pwd)"


####################################
# 并发控制
####################################
#并发个数
thread=5
#进程号
pid=$$
#管道文件
tmp_fifofile=${FWDIR}/${pid}.fifo
#创建管道文件
mkfifo ${tmp_fifofile}
#打开管道文件并定义为文件描述符5
exec 5<> ${tmp_fifofile}
#删除管道文件，因为文件描述符打开的文件即使删除句柄也不会被释放
rm -f ${tmp_fifofile}
#循环往管道文件中写入内容
for i in `seq ${thread}`
do
    #注意：&5等于文件描述符5，下面的命令是向文件写入回车
    echo >&5
done


# 设置请求URL
url="http://10.1.8.203:21801/edc-label-query-service/qryPortrait"

# 发送请求并计算耗时
function test_po() {
  # 设置POST数据
#  uuid=$(uuidgen)
#  post_data="{\"portraitId\":\"P00000010030\",\"msisdn\": \"13509323824\",\"queryType\": 2,\"tags\": [\"$uuid\"]}"
  post_data="{\"portraitId\":\"P00000010030\",\"msisdn\": \"13509323824\",\"queryType\": 2}"
  #start_time=$(date +"%Y-%m-%d %H:%M:%S.%3N")
  start_time=$(date +%s%N | cut -b1-13)
  curl -H "Content-type: application/json;charset=UTF-8" -H "reqChannelId: C000201" -H "Authorization: QzAwMDIwMTIwMjQxMTIwMDQwMjM1" -d "$post_data" $url
  #end_time=$(date +"%Y-%m-%d %H:%M:%S.%3N")
  end_time=$(date +%s%N | cut -b1-13)
  #echo "start:$start_time;end: $end_time"
  echo ""
  echo "${uuid} cost:$((end_time - start_time)) ms"
}


####################################
# 每秒执行几次，最多并发由管道控制
####################################
v_cost=0
function test_main() {
    s_start_time=$(date +%s%N | cut -b1-13)
    for ip in {1..10}
    do
      #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
      read -u 5
      {
        test_po
        #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
        echo >&5
      }&
    done
    wait
    s_end_time=$(date +%s%N | cut -b1-13)
    v_cost=$((s_end_time - s_start_time))
    echo "all_cost=${v_cost} ms"
}


####################################
# main，运行几秒，1秒不到的，要进行休眠
####################################
for sec in {1..2}
do
    test_main
    if [[ v_cost -lt 1000 ]]; then
        sleep_ws=$(( (1000 - v_cost)*1000 ))
        echo "要休眠的微秒=${sleep_ws}"
        usleep ${sleep_ws}
    else
        echo "本次不需要休眠，耗时${v_cost}超过1秒"
    fi
done
