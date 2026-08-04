#!/usr/bin/env bash
######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：2026-08-04
##修改内容：swap监控
##修改人员：cqx
#####################################################


######################################################################
##参数设置
######################################################################
##判断系统是windows还是Linux
system_name=`uname`
##路径
FWDIR="$(cd `dirname $0`;pwd)"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]路径=${FWDIR}"
##是否生产模式
is_sc="false"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]是否生产模式=${is_sc}"

# 持续采集 vmstat 数据，每 5 秒采集一组（每组 5 次，间隔 1 秒），写入日志
LOG_DIR="${FWDIR}/log/vmstat_monitor"
mkdir -p "$LOG_DIR"

while true; do
    LOG_FILE="${LOG_DIR}/vmstat_$(date +%Y%m%d).log"
    TIMESTAMP="[$(date '+%Y-%m-%d %H:%M:%S')]"
    echo "$TIMESTAMP --- Start vmstat snapshot ---" >> "$LOG_FILE"
    vmstat 1 5 >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    sleep 5   # 每 5 秒采集一轮，可根据需要调整
done
