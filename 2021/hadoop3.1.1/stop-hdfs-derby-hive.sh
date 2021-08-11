#!/usr/bin/env bash
#############################################################################################
##程序描述：停止dfs, derby, hiveserver2
##实现功能：
##运行周期：
##创建作者：
##创建日期：2021-08-11
#############################################################################################


######################################################################
##参数设置
######################################################################
##路径
FWDIR="$(cd `dirname $0`;pwd)"
##引入检查脚本
source ${FWDIR}/check-hdfs-derby-hive.sh


############################
##stop hiveserver2
############################
hiveserver2_pid=`check org.apache.hive.service.server.HiveServer2 hiveserver2`
if [[ ! ${hiveserver2_pid} ]]; then
  echo "hiveserver2 is not start."
else
  echo "hiveserver2 pid is ${hiveserver2_pid} , kill."
  kill -9 ${hiveserver2_pid}
  echo "kill ${hiveserver2_pid} result $?"
fi


############################
##stop derby
############################
derby_pid=`check org.apache.derby.drda.NetworkServerControl derby`
if [[ ! ${derby_pid} ]]; then
  echo "derby is not start."
else
  echo "derby pid is ${derby_pid}"
  sh ${DERBY_HOME}/data/stop-derby.sh
fi

############################
##stop hdfs
############################
dn_pid=`check org.apache.hadoop.hdfs.server.datanode.DataNode DataNode`
sn_pid=`check org.apache.hadoop.hdfs.server.namenode.SecondaryNameNode SecondaryNameNode`
nn_pid=`check org.apache.hadoop.hdfs.server.namenode.NameNode NameNode`
if [[ ! ${dn_pid} || ! ${sn_pid} || ! ${nn_pid} ]]; then
  echo "dn, sn, nn is not start."
else
  echo "dn pid is ${dn_pid}"
  echo "sn pid is ${sn_pid}"
  echo "nn pid is ${nn_pid}"
  /usr/bin/bash ${HADOOP_HOME}/sbin/stop-dfs.sh
fi