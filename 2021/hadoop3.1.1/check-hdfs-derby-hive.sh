#!/bin/bash
#############################################################################################
##程序描述：检查dfs, derby, hiveserver2
##实现功能：
##运行周期：
##创建作者：
##创建日期：2021-08-11
#############################################################################################


function check(){
key=$1
name=$2
#echo "key:${key}, name:${name}"
check_pid=`ps -ef|grep ${key}|grep -v grep|awk '{print $2}'`
if [[ ${check_pid} = "" ]]; then
#  echo "${name} is not start."
  echo ""
else
#  echo "${name} pid is ${check_pid}"
  echo "${check_pid}"
fi
}


############################
##check
############################
#check org.apache.hive.service.server.HiveServer2 hiveserver2
#check org.apache.derby.drda.NetworkServerControl derby
#check org.apache.hadoop.hdfs.server.datanode.DataNode DataNode
#check org.apache.hadoop.hdfs.server.namenode.SecondaryNameNode SecondaryNameNode
#check org.apache.hadoop.hdfs.server.namenode.NameNode NameNode