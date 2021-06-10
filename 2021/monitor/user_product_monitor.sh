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
#ll|grep -v gc|grep -v metrics|grep log|grep -v log.1|grep -v log.2|grep 'Apr 27'|awk '{print "grep 执行耗时 "$9"|grep '\''2021-04-27 08:'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{print cnt,exec,exec/cnt}'\''"}' |sh

monitor_path="D:/Document/Workspaces/Git/TestShell/2021/data/"

###############################
##进行告警，并判断是否能否重启
###############################
function exec1() {
path=$1
keyword=$2
mm=`date '+%b'`
dd=`date '+%d'`
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
ls -l ${path}|grep ${keyword}|grep -v gc|grep -v metrics|grep log|grep -v log.1|grep -v log.2|grep "$mm $dd"|awk '{print "grep 执行耗时 "v_path$9"|grep '\''"v_nowh"'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{if(cnt>0) print cnt,exec,exec/cnt; else print cnt,exec,cnt}'\''"}' v_nowh="$nowh" v_path="$path"|sh >> ${monitor_path}${keyword}.dat
#result1=`ls -l ${path}|grep ${keyword}|grep -v gc|grep -v metrics|grep log|grep -v log.1|grep -v log.2|grep "$mm $dd"|awk '{print "grep 执行耗时 "v_path$9"|grep '\''"v_nowh"'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{if(cnt>0) print cnt,exec,exec/cnt; else print cnt,exec,cnt}'\''"}' v_nowh="$nowh" v_path="$path"|sh`
##去空格
#result2=`echo ${result1}| sed 's/ //g'`
##判断是否有结果
#if [[ "${result2}" == "" ]]; then
#echo "a ${result1}"
#else
#echo "b ${result1}"
#fi
}

function exec2() {
path=$1
keyword=$2
mm=`date '+%b'`
dd=`date '+%d'`
hh=`date '+%H'`
nowh=`date '+%Y-%m-%d %H:'`
dd_len=`expr length "${dd}"`
if [[ ${dd_len} -eq 1 ]]; then
  dd=" ${dd}"
fi
echo "`date +"%Y-%m-%d %H:%M:%S"`"
echo "path is $path, keyword is $keyword"
echo "mm is $mm, dd is $dd, hh is $hh, nowh is $nowh"
ls -l ${path}|grep ${keyword}|grep -v gc|grep -v metrics|grep log|grep -v log.1|grep -v log.2|grep "$mm $dd"|awk '{print "grep 执行耗时 "v_path$9"|grep '\''"v_nowh"'\''|awk -F '\''：'\'' '\''{print $2,$4}'\''|awk -F '\''，执行结果 '\'' '\''{cnt+=$1;exec+=$2}END{if(cnt>0) print cnt,exec,exec/cnt; else print cnt,exec,cnt}'\''"}' v_nowh="$nowh" v_path="$path"|sh
}

###############################
##main
###############################
exec1 "D:/Document/Workspaces/Git/TestShell/2021/data/" "kafka_to_jdbc_mixed_user_product-worker"