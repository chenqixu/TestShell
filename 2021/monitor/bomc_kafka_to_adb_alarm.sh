#!/usr/bin/env bash
#############################################################################################
##程序描述：监控ogg实时同步adb程序
##实现功能：
##运行周期：每15分钟1次
##创建作者：
##创建日期：2021-07-06
#############################################################################################

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
##监控工具
NLTOOL_COMMAND="/bi/app/realtime-jstorm/nljstorm"
##日志路径
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  LOGS_PATH="${FWDIR}/../logs"
else
  LOGS_PATH="/bi/app/realtime-jstorm/logs"
fi
##标志位
##多线程-标志位
MULTIPLE_COUNT_IS_ERR=0
MULTIPLE_LAG_IS_ERR=0
MULTIPLE_CONSUMER_IS_ERR=0
MULTIPLE_OGG_SCHEMA_IS_ERR=0
##单线程-标志位
SINGLE_COUNT_IS_ERR=0
SINGLE_LAG_IS_ERR=0
SINGLE_CONSUMER_IS_ERR=0
##单线程新集群-标志位
SINGLE_10_COUNT_IS_ERR=0
SINGLE_10_LAG_IS_ERR=0
SINGLE_10_CONSUMER_IS_ERR=0
##监控告警值
multiple_kafka=0
single_kafka=0
crontab_task=0

######################################################################
##脚本核心逻辑处理
######################################################################
function monitor() {
##kafka监控
sh ${NLTOOL_COMMAND} kafka_group toolconfig/kafka_group.yaml --group_id ADB_TEST > ${LOGS_PATH}/kafka_group.log
#sh ${NLTOOL_COMMAND} kafka_group toolconfig/kafka_group.yaml --group_id adb_single > ${LOGS_PATH}/kafka_group_single.log
sh ${NLTOOL_COMMAND} kafka_group toolconfig/kafka_group_10.yaml > ${LOGS_PATH}/kafka_group_single_10.log

##ogg schema监控
sh ${NLTOOL_COMMAND} check_ogg_schema_multiple toolconfig/check_ogg_schema_multiple.yaml > ${LOGS_PATH}/check_ogg_schema_all.log

##定时任务监控
f_scp_to_local "10.45.179.119" "jstorm" "k+R40NHy" "/home/jstorm/jstormtasks/monitor/logs/kafkaToAdbCrontabMonitor.txt" "/tmp/bomc_file/"
crontab_task=`cat /tmp/bomc_file/kafkaToAdbCrontabMonitor.txt`
}

##多分区
multiple_topic="NMC_FLAT_B_BRB_CUS_BROADBAND_MOP_MANAGER_R_I_V1
NMC_FLAT_B_TRD_UN_COMMON_FLOW_R_I_V1"
#FLAT_B_BIL_OUTER_PLATFORM_USER_R_I_V1#定时同步
multiple_cnt_arr=(6 6)

##单分区
single_topic="NMC_TB_B_RES_CHNL_STORAGE_SALES_R_I_V1
NMC_TB_B_MKT_RES_PIECE_TYPE_GOODS_CONSUME_R_I_V1
NMC_TB_B_CUS_USER_PRODUCT_R_I_V1"
single_cnt_arr=(1 1 1)

##单分区新集群
single_10_topic="USER_ADDITIONAL_INFO
NMC_CCS_USER_ODFW_EXPORT_INFO
NMC_CCS_BROADBAND_USER
NMC_CCS_ITV_USERS
NMC_CCS_USER
NMC_TB_B_CUS_CUS_NAME_RECORD_INFO_R_I_V1
NMC_TB_B_RES_CHNL_STORAGE_SALES_R_I_V1
NMC_TB_B_MKT_RES_PIECE_TYPE_GOODS_CONSUME_R_I_V1
NMC_TB_B_CUS_USER_PRODUCT_R_I_V1"
single_10_cnt_arr=(1 1 1 1 1 1 1 1 1)

##积压告警值
limit=20
##适用于数据量比较大的话题
limit_max=500
##数据量比较大的话题
limit_max_topic=(NMC_TB_B_CUS_USER_PRODUCT_R_I_V1)

function add_flag() {
local flag=$1
eval "let $flag=$flag+1"
}

######################################################################
##判断kafka消费个数
##param1：日志名称
##param2：话题
##param3：话题消费个数
##param4：标志位名称
######################################################################
function count() {
local log_name=$1
local topic=$2
local cnt_arr=($3)
local flag_name=$4
local i=0
local t
for t in ${topic}; do
  local consumer_num=`cat ${LOGS_PATH}/${log_name}.log|awk '{if( $1 == v_name)print $1}' v_name=${t}|wc -l`
  if [[ "${consumer_num}" != "${cnt_arr[${i}]}" ]]; then
    fun_log 2 "【kafka消费个数异常】话题：${t} 目标消费个数：${cnt_arr[${i}]} 当前消费个数：${consumer_num}"
    add_flag "${flag_name}"
  fi
  i=`expr $i + 1`
done
}

######################################################################
##判断kafka消费积压
##param1：日志名称
##param2：话题
##param3：标志位名称
######################################################################
function lag() {
local log_name=$1
local topic=$2
local flag_name=$3
local t
for t in ${topic}; do
  local lag=`cat ${LOGS_PATH}/${log_name}.log|awk '{if( $1 == v_name) cnt+=$5}END{print cnt}' v_name=${t}`
  ##数据量比较大的话题
  if [[ ${limit_max_topic[@]} =~ ${t} ]]; then
    if [[ ${lag} -gt ${limit_max} ]]; then
      fun_log 2 "【kafka消费积压】话题：${t} 积压值：${lag} 告警值：${limit_max}"
      add_flag "${flag_name}"
    fi
    continue
  fi
  ##数据量比较小的话题
  if [[ ${lag} -gt ${limit} ]]; then
    fun_log 2 "【kafka消费积压】话题：${t} 积压值：${lag} 告警值：${limit}"
    add_flag "${flag_name}"
  fi
done
}

######################################################################
##判断应用有没消费
##param1：日志名称
##param2：话题
##param3：标志位名称
######################################################################
function isConsumer() {
local log_name=$1
local topic=$2
local flag_name=$3
local t
for t in ${topic}; do
  local lag=`cat ${LOGS_PATH}/${log_name}.log|awk '{if( $1 == v_name) print $1","$6}' v_name=${t}`
  local tmp_lag
  for tmp_lag in ${lag}; do
    local topic=`echo ${tmp_lag}|awk -F "," '{print $1}'`
    local consumer_id=`echo ${tmp_lag}|awk -F "," '{print $2}'`
    if [[ ${consumer_id} = "-" ]]; then
      fun_log 2 "【没有应用在消费】话题：${topic} 客户端id：${consumer_id}"
      add_flag "${flag_name}"
      break
    fi
  done
done
}

######################################################################
##判断源端是否调整字段
##param1：标志位名称
######################################################################
function ogg_schema() {
local flag_name=$1
local ret=`grep 最终校验结果 ${LOGS_PATH}/check_ogg_schema_all.log|awk '{print $2}'`
if [[ ${ret} != "true" ]]; then
  local t
  for t in `grep equal ${LOGS_PATH}/check_ogg_schema_all.log|awk '{print $1","$2","$3}'`; do
    local topic=`echo ${t}|awk -F "," '{print $1}'`
    local topic_ret=`echo ${t}|awk -F "," '{print $3}'`
    if [[ ${topic_ret} != "true" ]]; then
      fun_log 2 "【源端调整字段】话题：${topic}"
      add_flag "${flag_name}"
    fi
  done
fi
}

######################################################################
##脚本开始处理标志
######################################################################
fun_log 0 "--------------------------------开始脚本逻辑处理--------------------------------";
#monitor
count "kafka_group" "${multiple_topic}" "${multiple_cnt_arr[*]}" "MULTIPLE_COUNT_IS_ERR"
#count "kafka_group_single" "${single_topic}" "${single_cnt_arr[*]}" "SINGLE_COUNT_IS_ERR"
count "kafka_group_single_10" "${single_10_topic}" "${single_10_cnt_arr[*]}" "SINGLE_10_COUNT_IS_ERR"
isConsumer "kafka_group" "${multiple_topic}" "MULTIPLE_CONSUMER_IS_ERR"
#isConsumer "kafka_group_single" "${single_topic}" "SINGLE_CONSUMER_IS_ERR"
isConsumer "kafka_group_single_10" "${single_10_topic}" "SINGLE_10_CONSUMER_IS_ERR"
lag "kafka_group" "${multiple_topic}" "MULTIPLE_LAG_IS_ERR"
#lag "kafka_group_single" "${single_topic}" "SINGLE_LAG_IS_ERR"
lag "kafka_group_single_10" "${single_10_topic}" "SINGLE_10_LAG_IS_ERR"
ogg_schema "MULTIPLE_OGG_SCHEMA_IS_ERR"

#【数据同步】ADB实时同步-多线程-kafka消费异常监控告警
let multiple_kafka=${MULTIPLE_COUNT_IS_ERR}+${MULTIPLE_LAG_IS_ERR}+${MULTIPLE_CONSUMER_IS_ERR}
#【数据同步】ADB实时同步-多线程-源端调整字段异常监控告警
multiple_schema=${MULTIPLE_OGG_SCHEMA_IS_ERR}
#【数据同步】ADB实时同步-单线程-kafka消费异常监控告警
let single_kafka=${SINGLE_COUNT_IS_ERR}+${SINGLE_LAG_IS_ERR}+${SINGLE_CONSUMER_IS_ERR}+${SINGLE_10_COUNT_IS_ERR}+${SINGLE_10_CONSUMER_IS_ERR}+${SINGLE_10_LAG_IS_ERR}
#【数据同步】ADB实时同步-定时任务异常监控告警

fun_log 0 "【多线程-kafka消费异常监控告警】告警个数：${multiple_kafka}"
fun_log 0 "【多线程-源端调整字段异常监控告警】告警个数：${multiple_schema}"
fun_log 0 "【单线程-kafka消费异常监控告警】告警个数：${single_kafka}"
fun_log 0 "【定时任务异常监控告警】告警值：${crontab_task}"
##告警值写入目标文件
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  echo ${multiple_kafka} > ${FWDIR}/../tmp/bomc_file/kafkaToAdbMultipleKafkaMonitor.log
  echo ${multiple_schema} > ${FWDIR}/../tmp/bomc_file/kafkaToAdbMultipleSourceMonitor.log
  echo ${single_kafka} > ${FWDIR}/../tmp/bomc_file/kafkaToAdbSingleKafkaMonitor.log
else
  echo ${multiple_kafka} > /tmp/bomc_file/kafkaToAdbMultipleKafkaMonitor.txt
  echo ${multiple_schema} > /tmp/bomc_file/kafkaToAdbMultipleSourceMonitor.txt
  echo ${single_kafka} > /tmp/bomc_file/kafkaToAdbSingleKafkaMonitor.txt
fi

######################################################################
##脚本结束处理标志(模板)
######################################################################
fun_log 0 "--------------------------------脚本逻辑处理结束--------------------------------";