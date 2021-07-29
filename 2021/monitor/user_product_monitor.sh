#!/usr/bin/env bash
#############################################################################################
##程序描述：
##实现功能：
##运行周期：每小时1次
##创建作者：
##创建日期：2021-04-27
##修改日期：2021-06-10，修复23点时候取不到值的缺陷
#############################################################################################

#示例
#cd /home/jstorm/edc-app/jstorm-2.1.1/logs/kafka_to_jdbc_mixed_user_product_t2
#ll|grep -v gc|grep -v metrics|grep log|grep 'Apr 27'|awk '{print "grep 执行耗时 "$9"|grep '\''2021-04-27 08:'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{print cnt,exec,exec/cnt}'\''"}' |sh

#判断系统是windows还是Linux
system_name=`uname`
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  monitor_path="D:/Document/Workspaces/Git/TestShell/2021/data/"
  jstorm_logs="D:/Document/Workspaces/Git/TestShell/2021/logs/"
else
  monitor_path="/home/jstorm/jstormtasks/monitor/data/"
  jstorm_logs="/home/jstorm/edc-app/jstorm-2.1.1/logs/"
fi
#路径
FWDIR="$(cd `dirname $0`;pwd)"

###############################
##每小时执行一次，统计上个小时数据
###############################
function exec1() {
path=$1
keyword=$2
mm=`date '+%b'`
dd=`date '+%-d'`
hh=`date '+%H'`
nowh=`date -d '-1 hour' '+%Y-%m-%d %H:'`
if [[ "${hh}" -eq "00" ]]; then
  dd=`date -d '-1 hour' '+%d'`
fi
dd_len=`expr length "${dd}"`
if [[ ${dd_len} -eq 1 ]]; then
  dd=" ${dd}"
fi
echo "`date +"%Y-%m-%d %H:%M:%S"`" >> ${monitor_path}${keyword}.dat
echo "path is $path, keyword is $keyword" >> ${monitor_path}${keyword}.dat
echo "mm is $mm, dd is $dd, hh is $hh, nowh is $nowh" >> ${monitor_path}${keyword}.dat
ls -l ${path}|grep ${keyword}|grep -v gc|grep -v metrics|grep log|grep "$mm $dd"|awk '{print "grep 执行耗时 "v_path$9"|grep '\''"v_nowh"'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{print cnt,exec,exec/cnt}'\''"}' v_nowh="$nowh" v_path="$path"|sh >> ${monitor_path}${keyword}.dat
}


###############################
##统计当前小时数据
###############################
function exec2() {
path=$1
keyword=$2
mm=`date '+%b'`
dd=`date '+%-d'`
hh=`date '+%H'`
nowh=`date '+%Y-%m-%d %H:'`
dd_len=`expr length "${dd}"`
if [[ ${dd_len} -eq 1 ]]; then
  dd=" ${dd}"
fi
echo "`date +"%Y-%m-%d %H:%M:%S"`"
echo "path is $path, keyword is $keyword"
echo "mm is $mm, dd is $dd, hh is $hh, nowh is $nowh"
ls -l ${path}|grep ${keyword}|grep -v gc|grep -v metrics|grep log|grep "$mm $dd"|awk '{print "grep 执行耗时 "v_path$9"|grep '\''"v_nowh"'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{print cnt,exec,exec/cnt}'\''"}' v_nowh="$nowh" v_path="$path"|sh
}


###############################
##按小时统计数据
##param1 路径
##param2 关键字
##param3 小时周期：2021-07-23 00
###############################
function sum_hour() {
path=$1
keyword=$2
cycle="${3}:00:00"
mm=`date -d "${cycle}" '+%b'`
dd=`date -d "${cycle}" '+%-d'`
hh=`date -d "${cycle}" '+%H'`
nowh=`date -d "${cycle}" '+%Y-%m-%d %H:'`
dd_len=`expr length "${dd}"`
if [[ ${dd_len} -eq 1 ]]; then
  dd=" ${dd}"
fi
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  tmpfile="D:/Document/Workspaces/Git/TestShell/2021/tmp/${keyword}_sum_hour"
else
  tmpfile="/var/tmp/${keyword}_sum_hour"
fi
rm -f ${tmpfile}
ls -l ${path}|grep ${keyword}|grep -v gc|grep -v metrics|grep log|grep "$mm $dd"|awk '{print "grep 执行耗时 "v_path$9"|grep '\''"v_nowh"'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{print cnt,exec,exec/cnt}'\''"}' v_nowh="$nowh" v_path="$path"|sh >> ${tmpfile}
sum_cnt=`cat ${tmpfile}|awk '{cnt+=$1}END{print cnt}'`
all_cost=`cat ${tmpfile}|awk '{cnt+=$2}END{print cnt}'`
avg_cost=`expr ${all_cost} / ${sum_cnt}`
echo "【keyword】 ${keyword} 【cycle】 ${nowh} 【sum_cnt】 ${sum_cnt} 【all_cost】 ${all_cost}"
rm -f ${tmpfile}
}


###############################
##按天统计数据
##param1 路径
##param2 关键字
##param3 天周期：2021-07-23
###############################
function sum_day() {
path=$1
keyword=$2
cycle=$3
mm=`date -d "${cycle}" '+%b'`
dd=`date -d "${cycle}" '+%-d'`
hh=`date '+%H'`
nowh=$cycle
dd_len=`expr length "${dd}"`
if [[ ${dd_len} -eq 1 ]]; then
  dd=" ${dd}"
fi
echo "`date +"%Y-%m-%d %H:%M:%S"`"
echo "path is $path, keyword is $keyword"
echo "mm is $mm, dd is $dd, hh is $hh, nowh is $nowh"
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  tmpfile="D:/Document/Workspaces/Git/TestShell/2021/tmp/${keyword}"
else
  tmpfile="/var/tmp/${keyword}"
fi
echo "tmp is $tmpfile"
rm -f ${tmpfile}
ls -l ${path}|grep ${keyword}|grep -v gc|grep -v metrics|grep log|grep "$mm $dd"|awk '{print "grep 执行耗时 "v_path$9"|grep '\''"v_nowh"'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{print cnt,exec,exec/cnt}'\''"}' v_nowh="$nowh" v_path="$path"|sh >> ${tmpfile}
echo "-------------------"
sum_cnt=`cat ${tmpfile}|awk '{cnt+=$1}END{print cnt}'`
all_cost=`cat ${tmpfile}|awk '{cnt+=$2}END{print cnt}'`
avg_cost=`expr ${all_cost} / ${sum_cnt}`
echo "${keyword} ${cycle}"
echo "sum is: ${sum_cnt}"
echo "all cost is: ${all_cost}"
echo "avg cost is: ${avg_cost}"
rm -f ${tmpfile}
}


###############################
##检查标志
###############################
CHECK_TAG=0
function check_task_name() {
#检查是否在task_list里
for app1 in `cat ${FWDIR}/task_list.txt`; do
  if [[ "${app1}" = "${1}" ]]; then
    CHECK_TAG=1
    break
  fi
done
}


###############################
##打印task_list
###############################
function printTaskList() {
namelist=`cat ${FWDIR}/task_list.txt`;
echo "############################"
echo "##task_list: "
echo "############################"
echo "${namelist}"
echo "############################"
}


###############################
##main
###############################
if [[ $# -eq 1 ]]; then
  #$1 app_name or all
  if [[ "${1}" = "all" ]]; then
    for app1 in `cat ${FWDIR}/task_list.txt`; do
      exec1 "${jstorm_logs}${app1}/" "${app1}-worker"
    done
  else
    #检查是否在task_list里
    check_task_name "${1}"
    #执行
    if [[ ${CHECK_TAG} -ne 1 ]]; then
      echo "输入的参数不在task_list.txt中，请检查！"
      printTaskList
      exit 1
    else
      exec2 "${jstorm_logs}${1}/" "${1}-worker"
    fi
  fi
elif [[ $# -eq 3 ]]; then
  #$1 app_name
  #$2 type
  #$3 cycle
  #检查是否在task_list里
  check_task_name "${1}"
  #执行
  if [[ ${CHECK_TAG} -ne 1 ]]; then
    echo "输入的参数不在task_list.txt中，请检查！"
    printTaskList
    exit 1;
  elif [[ "${2}" = "sum_hour" ]]; then
    sum_hour "${jstorm_logs}${1}/" "${1}-worker" "$3"
  elif [[ "${2}" = "sum_day" ]]; then
    sum_day "${jstorm_logs}${1}/" "${1}-worker" "$3"
  else
    echo "输入的type参数不在[sum_day|sum_hour]中，请检查！"
    exit 1;
  fi
else
  echo "请输入参数："
  echo "1、输入app_name，查看app_name当前统计值"
  echo "2、输入app_name type[sum_day] cycle[yyyy-MM-dd]，查看app_name在某个周期的统计值"
  echo "3、输入app_name type[sum_hour] cycle[yyyy-MM-dd HH]，查看app_name在某个周期的统计值"
  printTaskList
  exit 1;
fi