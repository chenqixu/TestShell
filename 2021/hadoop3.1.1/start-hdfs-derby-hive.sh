#!/usr/bin/env bash
#############################################################################################
##程序描述：启动dfs, derby, hiveserver2
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
##start dfs
############################
echo "check dfs"
dn_pid=`check org.apache.hadoop.hdfs.server.datanode.DataNode DataNode`
sn_pid=`check org.apache.hadoop.hdfs.server.namenode.SecondaryNameNode SecondaryNameNode`
nn_pid=`check org.apache.hadoop.hdfs.server.namenode.NameNode NameNode`
if [[ ! ${dn_pid} || ! ${sn_pid} || ! ${nn_pid} ]]; then
  echo "start dfs ..."
  /usr/bin/bash ${HADOOP_HOME}/sbin/start-dfs.sh
fi


############################
##start derby
############################
echo "check derby"
derby_pid=`check org.apache.derby.drda.NetworkServerControl derby`
if [[ ! ${derby_pid} ]]; then
  echo "start derby ..."
  sh ${DERBY_HOME}/data/start-derby.sh
fi


############################
##start hiveserver2
############################
echo "check hiveserver2"
hiveserver2_pid=`check org.apache.hive.service.server.HiveServer2 hiveserver2`
if [[ ! ${hiveserver2_pid} ]]; then
  echo "start hiveserver2 ..."
  cd ${HIVE_HOME}
  nohup bin/hiveserver2 > logs/hiveserver2.log 2>&1 &
fi