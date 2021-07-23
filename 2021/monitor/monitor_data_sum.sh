#!/usr/bin/env bash
#############################################################################################
##程序描述：统计每月日峰值运维脚本
##实现功能：
##运行周期：
##创建作者：
##创建日期：2021-07-22
##修改日期：
#############################################################################################

#路径
FWDIR="$(cd `dirname $0`;pwd)"
#判断系统是windows还是Linux
system_name=`uname`
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  FILEPATH="${FWDIR}/../data/"
else
  FILEPATH="${FWDIR}/data/"
fi
FILENAME="monitor_data_sum"
#日志级别
INFO_LEVEL="INFO"
#统计月份
SUM_MONTH=""
#下个统计月
NEXT_SUM_MONTH=""

###############################
##sum end打印
##param1 TIME_TAG
##param2 HOUR_SUM
###############################
function printEnd() {
info "【sum end】TIME_TAG：${1}，HOUR_SUM：${2}"
}

###############################
##debug日志打印
##param1 日志
###############################
function debug() {
if [[ "${INFO_LEVEL}" = "DEBUG" ]]; then
  echo "【${FILENAME}】${1}"
fi
}

###############################
##info日志打印
##param1 日志
###############################
function info() {
echo "【${FILENAME}】${1}"
}

###############################
##main
##param1 SUM_MONTH
###############################
if [[ $# -eq 1 ]]; then
  SUM_MONTH=$1
  info "输入的月份为：${SUM_MONTH}"
  #校验一下
  CHECK_RET=`date -d "${SUM_MONTH}-01" && echo yes || echo no`
  if [[ "${CHECK_RET}" = "no" ]]; then
    info "输入的月份校验不通过！请检查！"
    exit 1;
  fi
  #计算下个统计月
  NEXT_SUM_MONTH=`date -d "${SUM_MONTH}-01 1 month" '+%Y-%m'`
  info "下个统计月：${NEXT_SUM_MONTH}"
  #正式运行
  for app_name in `cat ${FWDIR}/task_list.txt`; do
    FILENAME="${app_name}-worker.dat"
    MAX_VALUE=0
    MAX_DAY=""
    LINE_NUM=0
    START_LINE=0
    HOUR_SUM=0
    DAY_SUM=0
    HOUR_CNT=0
    TIME_TAG=""
    TIME_DAY=0
    OLD_TIME_DAY=0
    IS_NEXT_MONTH=0
    info "【FILE Read Start】：${FILEPATH}${FILENAME}"
    while read LINE
    do
      let LINE_NUM=LINE_NUM+1
      debug "【${LINE_NUM}】 ${LINE}"

      #判断结尾
      if [[ ${START_LINE} -ne 0 ]]; then
        #本月的判断 || 可能跨月
        if [[ (${LINE} == ${SUM_MONTH}*) || (${LINE} == ${NEXT_SUM_MONTH}*) ]]; then
          printEnd "${TIME_TAG}" "${HOUR_SUM}"
          let DAY_SUM+=${HOUR_SUM}
          let HOUR_CNT+=1
          START_LINE=0
          HOUR_SUM=0
          #跨月标志
          if [[ ${LINE} == ${NEXT_SUM_MONTH}* ]]; then
            IS_NEXT_MONTH=1
          fi
        else
          let HOUR_SUM+=`echo ${LINE}|awk '{print $1}'`
        fi
      fi

      #判断开头，开头需要过滤非7月数据
      if [[ (${LINE} =~ "mm is ") && (${LINE} =~ "nowh is ${SUM_MONTH}") ]]; then
        START_LINE=${LINE_NUM}
        TIME_TAG=`echo ${LINE}|awk -F 'nowh is ' '{print $2}'|awk -F ':' '{print $1}'`
        TIME_DAY=$((10#`date -d "${TIME_TAG}" '+%d'`))
        #判断OLD_TIME_DAY是不是0，表示第一次运行，还没有记录当天的信息
        if [[ ${OLD_TIME_DAY} -eq 0 ]]; then
          OLD_TIME_DAY=${TIME_DAY}
        fi
        #判断当前天是不是和获取到的时间不一致，不一致则进行时间切换
        if [[ ${OLD_TIME_DAY} -ne ${TIME_DAY} ]]; then
          info "find next day! DAY_SUM：${DAY_SUM}，HOUR_CNT：${HOUR_CNT}，OLD_TIME_DAY：${SUM_MONTH}-${OLD_TIME_DAY}，TIME_DAY：${SUM_MONTH}-${TIME_DAY}"
          if [[ ${MAX_VALUE} -eq 0 ]]; then
            MAX_VALUE=${DAY_SUM}
            MAX_DAY="${SUM_MONTH}-${OLD_TIME_DAY}"
          elif [[ ${DAY_SUM} -gt ${MAX_VALUE} ]]; then
            MAX_VALUE=${DAY_SUM}
            MAX_DAY="${SUM_MONTH}-${OLD_TIME_DAY}"
          fi
          OLD_TIME_DAY=${TIME_DAY}
          DAY_SUM=0
          HOUR_CNT=0
        fi
        debug "catch start line：${LINE_NUM}，TIME_TAG：${TIME_TAG}"
      fi
    done < ${FILEPATH}${FILENAME}
    #最后一个sum，这里没有跨月，本月未完成
    if [[ ${START_LINE} -ne 0 ]]; then
      #打印小时
      printEnd "${TIME_TAG}" "${HOUR_SUM}"
      let DAY_SUM+=${HOUR_SUM}
      let HOUR_CNT+=1
      START_LINE=0
      HOUR_SUM=0
      #打印天
      info "find next day! DAY_SUM：${DAY_SUM}，HOUR_CNT：${HOUR_CNT}，OLD_TIME_DAY：${SUM_MONTH}-${OLD_TIME_DAY}，TIME_DAY：${SUM_MONTH}-${TIME_DAY}"
      if [[ ${MAX_VALUE} -eq 0 ]]; then
        MAX_VALUE=${DAY_SUM}
        MAX_DAY="${SUM_MONTH}-${OLD_TIME_DAY}"
      elif [[ ${DAY_SUM} -gt ${MAX_VALUE} ]]; then
        MAX_VALUE=${DAY_SUM}
        MAX_DAY="${SUM_MONTH}-${OLD_TIME_DAY}"
      fi
      OLD_TIME_DAY=${TIME_DAY}
      DAY_SUM=0
      HOUR_CNT=0
    fi
    #有可能产生跨月，这里需要输出天
    if [[ ${IS_NEXT_MONTH} -eq 1 ]]; then
      #打印天
      info "find next day! DAY_SUM：${DAY_SUM}，HOUR_CNT：${HOUR_CNT}，OLD_TIME_DAY：${SUM_MONTH}-${OLD_TIME_DAY}，TIME_DAY：${SUM_MONTH}-${TIME_DAY}"
      if [[ ${MAX_VALUE} -eq 0 ]]; then
        MAX_VALUE=${DAY_SUM}
        MAX_DAY="${SUM_MONTH}-${OLD_TIME_DAY}"
      elif [[ ${DAY_SUM} -gt ${MAX_VALUE} ]]; then
        MAX_VALUE=${DAY_SUM}
        MAX_DAY="${SUM_MONTH}-${OLD_TIME_DAY}"
      fi
      OLD_TIME_DAY=${TIME_DAY}
      DAY_SUM=0
      HOUR_CNT=0
    fi
    #循环完成以后，输出MAX_VALUE
    info "MAX_DAY is：${MAX_DAY}，MAX_VALUE is：${MAX_VALUE}"
  done
else
  echo "请输入参数："
  echo "输入统计的月份，格式为：yyyy-MM，比如：2021-07"
  exit 1;
fi