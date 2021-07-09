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
. $TOOL_PATH/tool.func
##监控工具
NLTOOL_COMMAND="/bi/app/realtime-jstorm/nljstorm"
##日志路径
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  LOGS_PATH="${FWDIR}/../logs"
else
  LOGS_PATH="/bi/app/realtime-jstorm/logs"
fi
##标志位
COUNT_IS_ERR=0
LAG_IS_ERR=0
OGG_SCHEMA_IS_ERR=0
ISCONSUMER_IS_ERR=0
##监控告警值
bomc_ret=0

######################################################################
##脚本核心逻辑处理
######################################################################
function monitor() {
##kafka监控
sh ${NLTOOL_COMMAND} kafka_group toolconfig/kafka_group.yaml --group_id ADB_TEST > ${LOGS_PATH}/kafka_group.log
sh ${NLTOOL_COMMAND} kafka_group toolconfig/kafka_group.yaml --group_id adb_single > ${LOGS_PATH}/kafka_group_single.log

##ogg schema监控
sh ${NLTOOL_COMMAND} check_ogg_schema_multiple toolconfig/check_ogg_schema_multiple.yaml > ${LOGS_PATH}/check_ogg_schema_all.log
}

##多分区
multiple_topic="FLAT_NMC_CCS_BROADBAND_USER
FLAT_NMC_CCS_USER_ODFW
FLAT_USER_PRODUCT
FLAT_NMC_CCS_USER
FLAT_NMC_CCS_ITV_USERS
NMC_FLAT_B_BRB_CUS_BROADBAND_MOP_MANAGER_R_I_V1
FLAT_USER_ADDITIONAL_INFO
NMC_FLAT_B_CUS_CUS_NAME_RECORD_INFO_R_I_V1
NMC_FLAT_B_TRD_UN_COMMON_FLOW_R_I_V1"
#FLAT_B_BIL_OUTER_PLATFORM_USER_R_I_V1#定时同步
multiple_cnt_arr=(6 6 6 3 1 6 1 6 6)

##单分区
single_topic="NMC_TB_B_RES_CHNL_STORAGE_SALES_R_I_V1
NMC_TB_B_MKT_RES_PIECE_TYPE_GOODS_CONSUME_R_I_V1"
single_cnt_arr=(1 1)

##积压告警值
limit=200

function add_flag() {
flag=$1
eval "let $flag=$flag+1"
}

######################################################################
##判断kafka消费个数
##param1：日志名称
##param2：话题
##param3：话题消费个数
######################################################################
function count() {
log_name=$1
topic=$2
cnt_arr=($3)
i=0
for t in ${topic}; do
  comsumer_num=`cat ${LOGS_PATH}/${log_name}.log|awk '{if( $1 == v_name)print $1}' v_name=${t}|wc -l`
  if [[ "${comsumer_num}" != "${cnt_arr[${i}]}" ]]; then
    fun_log 2 "【kafka消费个数异常】话题：${t} 目标消费个数：${cnt_arr[${i}]} 当前消费个数：${comsumer_num}"
    add_flag "COUNT_IS_ERR"
  fi
  i=`expr $i + 1`
done
}

######################################################################
##判断kafka消费积压
##param1：日志名称
##param2：话题
######################################################################
function lag() {
log_name=$1
topic=$2
for t in ${topic}; do
  lag=`cat ${LOGS_PATH}/${log_name}.log|awk '{if( $1 == v_name) cnt+=$5}END{print cnt}' v_name=${t}`
  if [[ ${lag} -gt ${limit} ]]; then
    fun_log 2 "【kafka消费积压】话题：${t} 积压值：${lag} 告警值：${limit}"
    add_flag "LAG_IS_ERR"
  fi
done
}

######################################################################
##判断应用有没消费
##param1：日志名称
##param2：话题
######################################################################
function isConsumer() {
log_name=$1
topic=$2
for t in ${topic}; do
  lag=`cat ${LOGS_PATH}/${log_name}.log|awk '{if( $1 == v_name) print $1","$6}' v_name=${t}`
  for tmp_lag in ${lag}; do
    topic=`echo ${tmp_lag}|awk -F "," '{print $1}'`
    consumer_id=`echo ${tmp_lag}|awk -F "," '{print $2}'`
    if [[ ${consumer_id} = "-" ]]; then
      fun_log 2 "【没有应用在消费】话题：${topic} 客户端id：${consumer_id}"
      add_flag "ISCONSUMER_IS_ERR"
      break
    fi
  done
done
}

######################################################################
##判断源端是否调整字段
######################################################################
function ogg_schema() {
ret=`grep 最终校验结果 ${LOGS_PATH}/check_ogg_schema_all.log|awk '{print $2}'`
if [[ ${ret} != "true" ]]; then
  for t in `grep equal ${LOGS_PATH}/check_ogg_schema_all.log|awk '{print $1","$2","$3}'`; do
    topic=`echo ${t}|awk -F "," '{print $1}'`
    topic_ret=`echo ${t}|awk -F "," '{print $3}'`
    if [[ ${topic_ret} != "true" ]]; then
      fun_log 2 "【源端调整字段】话题：${topic}"
      add_flag "OGG_SCHEMA_IS_ERR"
    fi
  done
fi
}

######################################################################
##脚本开始处理标志
######################################################################
fun_log 0 "--------------------------------开始脚本逻辑处理--------------------------------";
#monitor
count "kafka_group" "${multiple_topic}" "${multiple_cnt_arr[*]}"
count "kafka_group_single" "${single_topic}" "${single_cnt_arr[*]}"
isConsumer "kafka_group" "${multiple_topic}"
isConsumer "kafka_group_single" "${single_topic}"
lag "kafka_group" "${multiple_topic}"
lag "kafka_group_single" "${single_topic}"
ogg_schema

let bomc_ret=${COUNT_IS_ERR}+${LAG_IS_ERR}*10000+${OGG_SCHEMA_IS_ERR}*100000000+${ISCONSUMER_IS_ERR}*1000000000000
fun_log 0 "个位十位百位千位：表示【kafka消费个数异常】个数"
fun_log 0 "万位十万位百万位千万位：表示【kafka消费积压】个数"
fun_log 0 "亿位十亿位百亿位千亿位：表示【源端调整字段】个数"
fun_log 0 "万亿位十万亿位百万亿位千万亿位：表示【没有应用在消费】个数"
fun_log 0 "告警值：${bomc_ret}"
##告警值写入目标文件
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  echo ${bomc_ret} > ${FWDIR}/../tmp/bomc_file/kafkaToAdbMonitor.log
else
  echo ${bomc_ret} > /tmp/bomc_file/kafkaToAdbMonitor.txt
fi

######################################################################
##脚本结束处理标志(模板)
######################################################################
fun_log 0 "--------------------------------脚本逻辑处理结束--------------------------------";