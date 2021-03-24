#!/usr/bin/env bash

#引入工具
. /bi/script/tool.func

echo "停止10.1.8.200 redis"
f_exec_cmd 10.1.8.200 "redis" "p*E#2qhT" "sh /home/redis/redis408/stop.sh"
echo "停止10.1.8.201 redis"
f_exec_cmd 10.1.8.201 "redis" "p*E#2qhT" "sh /home/redis/redis408/stop.sh"
echo "停止10.1.8.202 redis"
f_exec_cmd 10.1.8.202 "redis" "p*E#2qhT" "sh /home/redis/redis408/stop.sh"
echo "redis集群停止完成"