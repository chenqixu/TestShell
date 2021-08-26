#!/usr/bin/env bash
#############################################################################################
##程序描述：输出话单结果
##实现功能：
##运行周期：
##创建作者：
##创建日期：2021-08-26
#############################################################################################

if [[ $# -ne 1 ]]; then
  echo "请输入日志文件."
  exit -1
fi

##
task_log_name=$1

##
grep 采集数据文件GZ ${task_log_name} > s.log
grep 合并成功,更新文件状态为40 ${task_log_name} > e.log

##
cat s.log |awk '{print $2,$3"："$7"："$8}'|awk -F '：' '{print $1,substr($2,1,length($2)-7)}' > s1.log
cat e.log |awk '{print $2,$3"合并成功"$6}'|awk -F '合并成功' '{print $1,substr($2,4,length($2)-3)}' > e1.log

##
function readcdr() {
#clean
> ${task_log_name}.result
#read
while read line
do
  local s_time=`echo ${line}|awk '{print $1,$2}'`
  local s_name=`echo ${line}|awk '{print $3}'`
  local e_time=`grep $s_name e1.log|awk '{print $1,$2}'`
  local s_time_f=`date -d "$s_time" +%s`
  local e_time_f=`date -d "$e_time" +%s`
  let diff_time=$e_time_f-$s_time_f
  local result="文件: ${s_name} 处理时长: ${diff_time} 秒"
  #echo ${result}
  echo ${result} >> ${task_log_name}.result
done < s1.log
}

readcdr
rm -f s.log e.log s1.log e1.log