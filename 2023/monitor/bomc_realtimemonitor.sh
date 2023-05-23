#!/bin/sh
######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：2022-08-12
##修改内容：实时监测监控告警
##修改人员：cqx
#####################################################


######################################################################
##参数设置
######################################################################
##判断系统是windows还是Linux
system_name=`uname`
##路径
FWDIR="$(cd `dirname $0`;pwd)"
##引入工具类
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  TOOL_PATH=${FWDIR}/../../utils/
else
  TOOL_PATH=${FWDIR}/utils/
fi
. ${TOOL_PATH}/tool.func
##阀值
max_file_num=8000


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


####################################
# JStorm集群检查
####################################
function check_jstorm_cluster() {
_host=${1}
_command="sh /bi/sysapp/jstorm/bin/start_daemon.sh > /bi/sysapp/jstorm/logs/start_daemon.log"
_exec_command=`sshpass -p "yzs#15Ae" ssh -o StrictHostKeychecking=no -l edc_base ${_host} "${_command}"`
}


####################################
# 文件积压校验
####################################
function check_file_overstock() {
host=${1}
command=${2}
fileflag=${3}
overstock_num=`sshpass -p "yzs#15Ae" ssh -o StrictHostKeychecking=no -l edc_base ${host} "${command}"`
if [[ ${overstock_num} -gt ${max_file_num} ]]; then
  fun_log 1 "check_file_overstock ${fileflag} ${host} overstock_num: ${overstock_num} 超过阀值!"
  echo 1 >> ${FWDIR}/${pid}.${fileflag}
else
  fun_log 0 "check_file_overstock ${fileflag} ${host} overstock_num: ${overstock_num}"
fi
}


####################################
# 应用监测
####################################
function check_app() {
_app_host=${1}
_app_tag=${2}
_app_command="ps -ef|grep ${_app_tag}_realtimemonitor|grep -v grep|wc -l"
_app_exec=`sshpass -p "yzs#15Ae" ssh -o StrictHostKeychecking=no -l edc_base ${_app_host} "${_app_command}"`
if [[ ${_app_exec} -eq 0 ]]; then
  fun_log 1 "check_app ${_app_tag} ${_app_host} jstorm应用挂了!"
  echo 1 > ${FWDIR}/realtimemonitor_checkapp_${_app_tag}
else
  fun_log 0 "check_app ${_app_tag} ${_app_host} jstorm_app_num: ${_app_exec}"
fi
}


####################################
# 应用重启
####################################
function restart_app() {
_re_host=${1}
_re_command="sh /bi/app/realtime-jstorm/restart_monitor.sh"
_re_exec=`sshpass -p "yzs#15Ae" ssh -o StrictHostKeychecking=no -l edc_base ${_re_host} "${_re_command}"`
}


####################################
# main
# iot=1
# 4g xdr=10
# 5g xdr=100
# wlan=1000
# jiakuan=10000
# 4g xdr zte=100000
####################################
iot_num=0;
g4xdr_num=0;
g5xdr_num=0;
wlan_num=0;
jiakuan_num=0;
g4xdrzte_num=0;

#iot
#10.44.112.151~160
fun_log 0 "start monitor iot."
for ip in {151..160}
do
  #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
  read -u 5
  {
    check_jstorm_cluster "10.44.112.${ip}"
    check_file_overstock "10.44.112.${ip}" "ls /bi/dataprocess/realtimemonitor/5gmerge-zte/source|grep CSV|wc -l" "iot"
    check_app "10.44.112.${ip}" "iot"
    #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
    echo >&5
  }&
done
#10.44.147.51-65
for ip in {51..65}
do
  #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
  read -u 5
  {
    check_jstorm_cluster "10.44.147.${ip}"
    check_file_overstock "10.44.147.${ip}" "ls /bi/dataprocess/realtimemonitor/5gmerge-zte/source|grep CSV|wc -l" "iot"
    check_app "10.44.147.${ip}" "iot"
    #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
    echo >&5
  }&
done


#4g xdr
#10.44.112.31~80
fun_log 0 "start monitor 4g xdr."
for ip in {31..80}
do
  #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
  read -u 5
  {
    check_jstorm_cluster "10.44.112.${ip}"
    check_file_overstock "10.44.112.${ip}" "ls /bi/dataprocess/realtimemonitor/lte_xdr|grep -v txt.gz|grep txt|wc -l" "4gxdr"
    check_app "10.44.112.${ip}" "lte_xdr"
    #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
    echo >&5
  }&
done


#5g xdr
#10.44.112.101~150
fun_log 0 "start monitor 5g xdr."
for ip in {101..150}
do
  #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
  read -u 5
  {
    check_jstorm_cluster "10.44.112.${ip}"
    check_file_overstock "10.44.112.${ip}" "ls /bi/dataprocess/realtimemonitor/5g-zte_xdr_stream|grep CSV|wc -l" "5gxdr"
    check_app "10.44.112.${ip}" "5G"
    #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
    echo >&5
  }&
done


#wlan
#10.44.26.15
fun_log 0 "start monitor wlan."
#-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
read -u 5
{
  check_jstorm_cluster "10.44.26.15"
  check_file_overstock "10.44.26.15" "ls /bi/dataprocess/realtimemonitor/wlanmerge|grep .txt|grep _14-|wc -l" "wlan"
  check_app "10.44.26.15" "wlan"
  #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
  echo >&5
}&

#jia kuan
#10.44.112.167~196
fun_log 0 "start monitor jia kuan."
for ip in {167..196}
do
  #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
  read -u 5
  {
    check_jstorm_cluster "10.44.112.${ip}"
    check_file_overstock "10.44.112.${ip}" "ls /bi/dataprocess/realtimemonitor/jiakuangmerge|grep jiakuang_|wc -l" "jiakuan"
    check_app "10.44.112.${ip}" "jiakuang"
    #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
    echo >&5
  }&
done


#4g xdr zte
#10.44.147.1-10.44.147.50
fun_log 0 "start monitor 4gxdrzte."
for ip in {1..50}
do
  #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
  read -u 5
  {
    check_jstorm_cluster "10.44.147.${ip}"
    check_file_overstock "10.44.147.${ip}" "ls /bi/dataprocess/realtimemonitor/4gxdr-zte|grep CSV|wc -l" "4gxdrzte"
    check_app "10.44.147.${ip}" "4gxdr-zte"
    #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
    echo >&5
  }&
done


####################################
# finish
####################################
wait;

if [[ -s ${FWDIR}/${pid}.iot ]]; then
  iot_num=1
fi
if [[ -s ${FWDIR}/${pid}.4gxdr ]]; then
  g4xdr_num=10
fi
if [[ -s ${FWDIR}/${pid}.5gxdr ]]; then
  g5xdr_num=100
fi
if [[ -s ${FWDIR}/${pid}.wlan ]]; then
  wlan_num=1000
fi
if [[ -s ${FWDIR}/${pid}.jiakuan ]]; then
  jiakuan_num=10000
fi
if [[ -s ${FWDIR}/${pid}.4gxdrzte ]]; then
  g4xdrzte_num=100000
fi
rm -f ${FWDIR}/${pid}.iot
rm -f ${FWDIR}/${pid}.4gxdr
rm -f ${FWDIR}/${pid}.5gxdr
rm -f ${FWDIR}/${pid}.wlan
rm -f ${FWDIR}/${pid}.jiakuan
rm -f ${FWDIR}/${pid}.4gxdrzte


fun_log 0 "${iot_num} ${g4xdr_num} ${g5xdr_num} ${wlan_num} ${jiakuan_num} ${g4xdrzte_num}"
let result_num=${iot_num}+${g4xdr_num}+${g5xdr_num}+${wlan_num}+${jiakuan_num}+${g4xdrzte_num}
fun_log 0 "monitor is finish. result_num is ${result_num}"
####################################
# 写入告警值
####################################
echo ${result_num} > /tmp/bomc_file/bomc_realtimemonitor.txt


####################################
# 判断是否重启
####################################
if [[ -f ${FWDIR}/realtimemonitor_checkapp_iot && `cat ${FWDIR}/realtimemonitor_checkapp_iot` -eq 1 ]]; then
  fun_log 1 "重启iot_realtimemonitor"
  restart_app "10.44.112.151"
fi
if [[ -f ${FWDIR}/realtimemonitor_checkapp_lte_xdr && `cat ${FWDIR}/realtimemonitor_checkapp_lte_xdr` -eq 1 ]]; then
  fun_log 1 "重启4gxdr_realtimemonitor"
  restart_app "10.44.112.31"
fi
if [[ -f ${FWDIR}/realtimemonitor_checkapp_5G && `cat ${FWDIR}/realtimemonitor_checkapp_5G` -eq 1 ]]; then
  fun_log 1 "重启5gxdr_realtimemonitor"
  restart_app "10.44.112.101"
fi
if [[ -f ${FWDIR}/realtimemonitor_checkapp_wlan && `cat ${FWDIR}/realtimemonitor_checkapp_wlan` -eq 1 ]]; then
  fun_log 1 "重启wlan_realtimemonitor"
  restart_app "10.44.26.15"
fi
if [[ -f ${FWDIR}/realtimemonitor_checkapp_jiakuang && `cat ${FWDIR}/realtimemonitor_checkapp_jiakuang` -eq 1 ]]; then
  fun_log 1 "重启jiakuang_realtimemonitor"
  restart_app "10.44.112.167"
fi
if [[ -f ${FWDIR}/realtimemonitor_checkapp_4gxdr-zte && `cat ${FWDIR}/realtimemonitor_checkapp_4gxdr-zte` -eq 1 ]]; then
  fun_log 1 "重启4gxdr-zte_realtimemonitor"
  restart_app "10.44.147.1"
fi
rm -f ${FWDIR}/realtimemonitor_checkapp_iot
rm -f ${FWDIR}/realtimemonitor_checkapp_lte_xdr
rm -f ${FWDIR}/realtimemonitor_checkapp_5G
rm -f ${FWDIR}/realtimemonitor_checkapp_wlan
rm -f ${FWDIR}/realtimemonitor_checkapp_jiakuang
rm -f ${FWDIR}/realtimemonitor_checkapp_4gxdr-zte


####################################
# 退出
####################################
exit 0;
