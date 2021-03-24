#!/usr/bin/env bash

#引入工具
. /bi/script/tool.func

echo "检查10.1.8.200 redis"
f_exec_cmd 10.1.8.200 "redis" "p*E#2qhT" "sh /home/redis/redis408/status.sh"
echo "检查10.1.8.201 redis"
f_exec_cmd 10.1.8.201 "redis" "p*E#2qhT" "sh /home/redis/redis408/status.sh"
echo "检查10.1.8.202 redis"
f_exec_cmd 10.1.8.202 "redis" "p*E#2qhT" "sh /home/redis/redis408/status.sh"