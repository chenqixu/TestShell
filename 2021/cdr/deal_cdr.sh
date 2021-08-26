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


#########################
##参数
#########################
task_log_name=$1


#########################
##进度条
#########################
function progressbar() {
grep_cnt=0
all_cnt=`cat s.log|wc -l`
while [[ ${grep_cnt} -ne ${all_cnt} ]]
do
  grep_cnt=`cat ${task_log_name}.result|wc -l`
  let ps=grep_cnt*100/all_cnt
  printf "[%d%%]\r" ${ps}
#  printf "[%-100s]%d%%\r" $b $ps
  sleep 1
#  b=#$b
done
echo
}


#########################
##过滤关键字
#########################
grep 采集数据文件GZ ${task_log_name} > s.log
grep 合并成功,更新文件状态为40 ${task_log_name} > e.log


#########################
##进一步过滤关键字
#########################
cat s.log |awk '{print $2,$3"："$7"："$8}'|awk -F '：' '{print $1,substr($2,1,length($2)-7)}' > s1.log
cat e.log |awk '{print $2,$3"合并成功"$6}'|awk -F '合并成功' '{print $1,substr($2,4,length($2)-3)}' > e1.log


#########################
##处理
#########################
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


#########################
##main
#########################
#进度条
progressbar &
#处理
readcdr
#等待进度条
wait
#清理文件
rm -f s.log e.log s1.log e1.log
