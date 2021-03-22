#!/usr/bin/env bash
#############################################################################################
##程序描述：根据传入的阀值，判断jstorm应用是否需要重启
##实现功能：
##运行周期：由上游调用者决定
##创建作者：
##创建日期：2021-03-18
#############################################################################################

###############################
##参数设置
###############################
#路径
FWDIR="$(cd `dirname $0`;pwd)"
#引入工具类
TOOL_PATH=${FWDIR}/../utils/
. $TOOL_PATH/tool.func
#日志路径
log_path=${FWDIR}/data/
#告警时间配置路径
alarm_time_config_path=${FWDIR}/config
#单次异常重启时间，目前是允许半小时重启一次
check_times=1800
#需要重启的消费者id
exclusive_consumers_arr=(MID_POSITION_RESUME_KFK_J REALTIME_LOCATION_J_ALTIBASE POSITION_SCENE_ALTIBASE);

###############################
##传入的参数判断与设置
###############################
if [[ $# -ne 2 ]]; then
  fun_log 2 "there is no enough args, you need input restart_flag(1.restart 2.no restart), check_num.";
  exit 1;
fi
restart_flag=$1
check_num=$2

###############################
##通过日志判断是否积压，如果积压则进行重启
###############################
function check_consumer() {
  consumer=${1}
  c_consumer_file="${log_path}${consumer}"
  overstock=`awk '{total+=$5}END{print total}' ${c_consumer_file}`
  #去掉.log
  consumer_name=${consumer%????}
  #排除不需要重启的消费者
  if [[ ${exclusive_consumers_arr[@]} =~ ${consumer_name} ]]; then
    fun_log 0 "${consumer_name} 当前积压值: ${overstock}"
    #需要重启，进行判断是否重启
    alarm_and_restart ${overstock} ${consumer_name}
  else
    fun_log 0 "${consumer_name} 是被排除的消费者，所以不进行处理."
  fi
}

###############################
##进行告警，并判断是否能否重启
###############################
function alarm_and_restart() {
  a_overstock=${1}
  a_name=${2}
  diff_value=0
  #判断积压值是否大于预警值
  if [[ ${a_overstock} -gt ${check_num} ]]; then
    #当前检查时间
    now_check_time=`date '+%Y-%m-%d %H:%M:%S'`
    now_check_time_m=`date -d "${now_check_time}" +%s`
    fun_log 1 "${a_name} 当前检查时间 : ${now_check_time}, 检查阀值 : ${check_num}, 当前积压值 : ${a_overstock}, 超过阀值."
    #读取日志里的上次重启时间
    #判断配置文件是否存在
    alarm_config_file=${alarm_time_config_path}/${a_name}.alarm
    if [[ ! -f "${alarm_config_file}" ]]; then
      #文件不存在，创建一个
      fun_log 1 "${alarm_config_file}文件不存在，创建一个"
      echo ${now_check_time} > ${alarm_config_file}
    fi
    last_time=`cat ${alarm_config_file}`
    last_time_m=`date -d "${last_time}" +%s`
    #计算差值=当前检查时间-上次重启时间
    let diff_value=now_check_time_m-last_time_m
    #如果差值大于预设值check_times，就可以进行重启操作
    if [[ ${diff_value} -gt ${check_times} ]]; then
      #更新配置文件中的重启时间
      echo ${now_check_time} > ${alarm_config_file}
      #判断重启标志，1：允许重启；其他：不允许重启
      if [[ ${restart_flag} -eq 1 ]]; then
        fun_log 1 "${a_name} 准备重启, 重启时间 : ${now_check_time}"
        #远程调用重启命令
        #f_exec_cmd 10.48.134.118 "jstorm" "k+R40NHy" "sh /home/jstorm/jstormtasks/update/20200929/shell/restart.sh ${a_name}"
        ${FWDIR}/restart.sh ${a_name}
      else
        #不重启
        fun_log 1 "${a_name} 不进行重启, 因为重启标志为 : ${restart_flag}."
      fi
    else
      fun_log 1 "${a_name} 不满足重启条件, 上次重启时间 : ${last_time}, 当前检查时间 : ${now_check_time}, 差值(s) : ${diff_value}"
    fi
  fi
}

###############################
##main
###############################
fun_log 0 "====启动====[参数]是否重启:${restart_flag}(1.restart 2.not restart), 检查阀值:${check_num}"
#扫描日志文件
files=`ls ${log_path}`
#循环日志文件，读取积压数据进行判断是否需要进行重启操作
for i in ${files}; do
  check_consumer "${i}"
done
