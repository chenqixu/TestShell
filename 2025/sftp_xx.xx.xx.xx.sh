#!/usr/bin/env bash
######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：2025-12-17
##修改内容：sftp并发传输文件，提高主机CPU利用率，避免成为低效资源
##修改人员：cqx
#####################################################

# 后台启动写法
# nohup ./sftp_10.44.215.21.sh > sftp_10.44.215.21.info 2>&1 &

function sftp1(){
  cd /bi/app/realtime-jstorm/
  sh nljstorm sftp toolconfig/sftp${1}_puts.yaml
}

time_array=(13 14 15 16 17 18)
start_time=$(date +"%Y-%m-%d %H:%M:%S.%3N")
echo "[${start_time}] 指定时间=${time_array[*]}"

while true
do
    start_time=$(date +"%Y-%m-%d %H:%M:%S.%3N")
    start_hour=$(date +"%H")
    if [[ "${time_array[*]}" =~ "${start_hour}" ]]; then
        echo "[${start_time}] 当前小时${start_hour}属于指定时间, 执行"
        # 执行
        sftp1 &
        sftp1 1 &
        sftp1 2 &
        sftp1 3 &
        sftp1 4 &
        # 等待执行完成
        wait
        # 每间隔5分钟执行一次
        sleep 300
    else
        echo "[${start_time}] 当前小时${start_hour}非指定时间"
    fi
    sleep 5
done