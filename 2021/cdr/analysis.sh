#!/usr/bin/env bash
#############################################################################################
##程序描述：针对话单的结果进行分析
##实现功能：
##运行周期：
##创建作者：
##创建日期：2021-08-26
#############################################################################################

if [[ $# -ne 1 ]]; then
  echo "请输入需要分析的文件."
  exit -1
fi

##
task_result_name=$1

##
#总量
all_cnt=`cat ${task_result_name} |wc -l`
echo "总量 ${all_cnt}"
#小于10秒
cnt_10=`cat ${task_result_name} |awk '{if($4<10)print $4}'|wc -l`
echo "小于10秒 ${cnt_10} 占比 `awk 'BEGIN{printf "%.1f%%\n",('$cnt_10'/'$all_cnt')*100}'`"
#小于20秒
cnt_20=`cat ${task_result_name} |awk '{if($4<20 && $4>=10)print $4}'|wc -l`
echo "10秒~20秒 ${cnt_20} 占比 `awk 'BEGIN{printf "%.1f%%\n",('$cnt_20'/'$all_cnt')*100}'`"
#小于30秒
cnt_30=`cat ${task_result_name} |awk '{if($4<30 && $4>=20)print $4}'|wc -l`
echo "20秒~30秒 ${cnt_30} 占比 `awk 'BEGIN{printf "%.1f%%\n",('$cnt_30'/'$all_cnt')*100}'`"
#小于60秒
cnt_60=`cat ${task_result_name} |awk '{if($4<60 && $4>=30)print $4}'|wc -l`
echo "30秒~60秒 ${cnt_60} 占比 `awk 'BEGIN{printf "%.1f%%\n",('$cnt_60'/'$all_cnt')*100}'`"
#小于120秒
cnt_120=`cat ${task_result_name} |awk '{if($4<120 && $4>=60)print $4}'|wc -l`
echo "60秒~120秒 ${cnt_120} 占比 `awk 'BEGIN{printf "%.1f%%\n",('$cnt_120'/'$all_cnt')*100}'`"
#大于等于120秒
cnt_lt_120=`cat ${task_result_name} |awk '{if($4>=120)print $4}'|wc -l`
echo "大于等于120秒 ${cnt_lt_120} 占比 `awk 'BEGIN{printf "%.1f%%\n",('$cnt_lt_120'/'$all_cnt')*100}'`"