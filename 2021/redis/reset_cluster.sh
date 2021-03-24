#!/usr/bin/env bash

#引入工具
. /bi/script/tool.func

#停止集群
/home/redis/redis408/bin/cluster_stop.sh

#检查是否停止
status=`/home/redis/redis408/bin/cluster_status.sh|wc -l`
if [[ ${status} = 3 ]]; then
  echo "集群已经停止"
  #数据清理
  echo "清理10.1.8.200数据"
  f_exec_cmd 10.1.8.200 "redis" "p*E#2qhT" "rm -f /home/redis/redis408/cluster/*;rm -f /home/redis/redis408/data/*;rm -f /home/redis/redis408/logs/*;"
  echo "清理10.1.8.201数据"
  f_exec_cmd 10.1.8.201 "redis" "p*E#2qhT" "rm -f /home/redis/redis408/cluster/*;rm -f /home/redis/redis408/data/*;rm -f /home/redis/redis408/logs/*;"
  echo "清理10.1.8.202数据"
  f_exec_cmd 10.1.8.202 "redis" "p*E#2qhT" "rm -f /home/redis/redis408/cluster/*;rm -f /home/redis/redis408/data/*;rm -f /home/redis/redis408/logs/*;"

  #启动集群
  /home/redis/redis408/bin/cluster_start.sh

  #绑定集群
  /home/redis/redis408/redis/src/redis-trib.rb create --replicas 1 10.1.8.200:10000 10.1.8.200:10001 10.1.8.201:10000 10.1.8.201:10001 10.1.8.202:10000 10.1.8.202:10001 10.1.8.200:30000 10.1.8.200:30001 10.1.8.201:30000 10.1.8.201:30001 10.1.8.202:30000 10.1.8.202:30001
else
  echo "集群还未停止"
fi