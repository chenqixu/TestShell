#!/usr/bin/env bash
#############################################################################################
##程序描述：根据传入的阀值，判断jstorm应用是否需要重启
##实现功能：
##运行周期：由上游调用者决定
##创建作者：
##创建日期：2021-03-19
#############################################################################################

###############################
##参数设置
###############################
#路径
FWDIR="$(cd `dirname $0`;pwd)"
#引入工具类
TOOL_PATH=${FWDIR}/../utils/
. $TOOL_PATH/tool.func
#加载环境变量
#source /home/jstorm/jstormtasks/update/20200929/shell/env.sh
#设置jstorm执行路径
exec_jstorm=$TOOL_PATH/jstorm

###############################
##传入的参数判断与设置
###############################
if [[ $# -ne 1 ]]; then
  fun_log 2 "there is no enough args, you need input app_name.";
  fun_log 0 "gsdb : MID_POSITION_RESUME_KFK_J|REALTIME_LOCATION_J_ALTIBASE|POSITION_SCENE_ALTIBASE";
  fun_log 0 "tt : REALTIME_LOCATION_J_TT|POSITION_SCENE_J";
  exit 1;
fi
app_name=$1

###############################
##从jstorm list中获取当前应用名称，并重启
###############################
function app_restart() {
  filter_name=${1}
  current_name=`${exec_jstorm} list|grep ${filter_name}|grep name|awk -F '"' '{print $4}'`
  if [[ ! ${current_name} ]]; then
    fun_log 1 "jstorm中没有找到这个应用 ${filter_name}"
  else
    fun_log 0 "过滤名称为 : ${filter_name} , 准备重启 : ${current_name}"
    ${exec_jstorm} restart ${current_name}
  fi
}

###############################
##main
###############################
if [[ "${app_name}" =~ "MID_POSITION_RESUME_KFK_J" ]]; then
  app_restart "location_merge"
elif [[ "${app_name}" =~ "POSITION_SCENE_ALTIBASE" ]]; then
  app_restart "position_scene_altibase"
elif [[ "${app_name}" =~ "REALTIME_LOCATION_J_ALTIBASE" ]]; then
  app_restart "realtime_location_altibase"
elif [[ "${app_name}" =~ "REALTIME_LOCATION_J_TT" ]]; then
  app_restart "${app_name}"
elif [[ "${app_name}" =~ "POSITION_SCENE_J" ]]; then
  app_restart "${app_name}"
else
  fun_log 1 "${app_name} 未配置, 不进行处理."
fi
