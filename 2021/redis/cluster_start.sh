#!/usr/bin/env bash

#引入工具
. /bi/script/tool.func

echo "启动10.1.8.200 redis"
f_exec_cmd 10.1.8.200 "redis" "p*E#2qhT" "sh /home/redis/redis408/start.sh"
echo "启动10.1.8.201 redis"
f_exec_cmd 10.1.8.201 "redis" "p*E#2qhT" "sh /home/redis/redis408/start.sh"
echo "启动10.1.8.202 redis"
f_exec_cmd 10.1.8.202 "redis" "p*E#2qhT" "sh /home/redis/redis408/start.sh"
echo "redis集群启动完成"