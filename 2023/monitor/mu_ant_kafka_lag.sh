#!/usr/bin/env bash
######################################################################
##蚂蚁flink任务偏移量监控-并发版本
######################################################################

######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：20230913
##修改内容：新建
##修改人员：陈棋旭
#####################################################


######################################################################
##配置
######################################################################
##路径
FWDIR="$(cd `dirname $0`;pwd)"


######################################################################
##通用函数(模板)：各脚本使用的通用函数，不够的在模板中添加
######################################################################
#########日志输出函数
##参数1：类型，0 info 1 warn 2 error
##参数2：日志内容
fun_log()
{
        case $1 in
                0 )
                        log_lev="INFO";
                ;;
                1 )
                        log_lev="WARN";
                ;;
                2 )
                        log_lev="ERROR";
                ;;
                * )
                        log_lev="no defined";
                ;;
        esac
        echo -e "`date +"%Y-%m-%d %H:%M:%S"` [${log_lev}] $2";
}


##返回结果处理
_exit()
{
	if [[ ${1} -eq 0 ]] ; then
		fun_log 0 "--------------------------------脚本逻辑处理结束--------------------------------";
		##执行结束时间
		end_time=`date +"%s"`;
		##执行耗时
		elapse=$((${end_time}-${begin_time}));
		fun_log 0 "脚本执行耗时:${elapse} s";
		exit 0;
	else
		fun_log 2 "--------------------------------脚本逻辑处理失败--------------------------------";
		exit 1;
	fi;
}


######################################################################
##解析kafka偏移量日志， 生成数据文件
######################################################################
KEY="TOPIC"

get_kafka_data_load()
{
  local LINE_P1=$1
  local FLAG=0
  local LINE=""
  local p_group_id=`echo $LINE_P1|awk -F ',' '{print $1}'`
  local p_task_name=`echo $LINE_P1|awk -F ',' '{print $2}'`
  local kafka_cluster=`echo $LINE_P1|awk -F ',' '{print $3}'`
  local log_file=${kafka_cluster}_${p_group_id}.log
  local OUT_NUM=0

  ##通过消费组获取偏移量
  fun_log 0 "--------------------------------通过消费组获取偏移量 p_group_id=${p_group_id} p_task_name=${p_task_name} kafka_cluster=${kafka_cluster} log_file=${log_file}--------------------------------"
  sh /bi/app/realtime-jstorm/nljstorm kafka_group toolconfig/kafka_group_${kafka_cluster}.yaml --group_id ${p_group_id} > ${FWDIR}/logs/kafka_group_log/${log_file}

  cat ${FWDIR}/logs/kafka_group_log/${log_file}|while read LINE
  do
    #fun_log 0 "[flag] ${FLAG} [line] ${LINE}"
    if [[ $FLAG -eq 1 ]]; then
      let OUT_NUM+=1
      echo $LINE|awk -v var1="$p_group_id" -v var2="$p_task_name" '{print var2","var1","$1","$2","$3","$4","$5}' >> ${FWDIR}/logs/kafka_load_data/${log_file}
    fi
    if [[ $LINE == *$KEY* ]]; then
      FLAG=1
      fun_log 0 "--------------------------------FLAG=1 log_file=${log_file}--------------------------------"
    fi
  done
  fun_log 0 "--------------------------------OUT_NUM=${OUT_NUM} log_file=${log_file}--------------------------------"
  ##生成标志文件
  touch ${FWDIR}/logs/kafka_load_flag/${log_file}
}


######################################################################
##脚本开始处理标志(模板)
######################################################################
fun_log 0 "--------------------------------开始脚本逻辑处理--------------------------------";
##执行开始时间
begin_time=`date +"%s"`;


####################################
# 并发控制
####################################
#并发个数
thread=8
#进程号
pid=$$
#管道文件
tmp_fifofile=${FWDIR}/${pid}.fifo
fun_log 0 "--------------------------------并发个数: [并发个数]${thread} [进程号]${pid} [管道文件]${tmp_fifofile}-----"
#创建管道文件
mkfifo ${tmp_fifofile}
#打开管道文件并定义为文件描述符8
exec 8<> ${tmp_fifofile}
#删除管道文件，因为文件描述符打开的文件即使删除句柄也不会被释放
rm -f ${tmp_fifofile}
#循环往管道文件中写入内容
for i in `seq ${thread}`
do
    #注意：&8等于文件描述符8，下面的命令是向文件写入回车
    echo >&8
done


######################################################################
##清理历史文件
######################################################################
fun_log 0 "--------------------------------清理历史文件--------------------------------"
#从配置库查询消费组
rm /bi/app/realtime-jstorm/data/ant_kafka_lag/*
#遍历消费组1
rm ${FWDIR}/logs/kafka_group_log/*
#遍历消费组2
rm ${FWDIR}/logs/kafka_load_data/*
#清理标志文件
rm ${FWDIR}/logs/kafka_load_flag/*
#合并大文件,数据导入oracle
rm ${FWDIR}/logs/kafka_load_data.txt


######################################################################
##从配置库查询消费组
######################################################################
fun_log 0 "--------------------------------从配置库查询消费组--------------------------------"
sh /bi/app/realtime-jstorm/nljstorm oracle_to_file toolconfig/ant_oracle_to_file.yaml


######################################################################
##遍历消费组
######################################################################
LAG_CNT=`cat /bi/app/realtime-jstorm/data/ant_kafka_lag/data0.txt|wc -l`
fun_log 0 "--------------------------------遍历消费组 [LAG_CNT]=${LAG_CNT}--------------------------------"
cat /bi/app/realtime-jstorm/data/ant_kafka_lag/data0.txt | while read LINE_LAG
do
  #-u表示对文件描述符进行读取，如果能读取则执行下面的命令，如果不能则等待
  read -u8
  {
    get_kafka_data_load "${LINE_LAG}"
    #由于之前是从管道文件中读走了一行，这里要在还回去一行，让后面的进程进行使用
    echo >&8
  } &
done


####################################
# finish
####################################
fun_log 0 "--------------------------------等待任务并发完成--------------------------------"
#等待任务并发完成
wait
fun_log 0 "--------------------------------标志文件-辅助判断--------------------------------"
#标志文件-辅助判断
FLAG_CNT=`ls ${FWDIR}/logs/kafka_load_flag/|wc -l`
while [ ${FLAG_CNT} != ${LAG_CNT} ]
do
  sleep 1
  fun_log 0 "标志文件没到位. sleep 1. [FLAG_CNT]=${FLAG_CNT}."
  FLAG_CNT=`ls ${FWDIR}/logs/kafka_load_flag/|wc -l`
done
#合并大文件
fun_log 0 "--------------------------------任务并发完成, 合并大文件--------------------------------"
cat ${FWDIR}/logs/kafka_load_data/* > ${FWDIR}/logs/kafka_load_data.txt


######################################################################
##数据导入oracle
######################################################################
fun_log 0 "--------------------------------数据导入oracle--------------------------------"
sh /bi/app/realtime-jstorm/nljstorm file_to_oracle toolconfig/ant_file_to_oracle.yaml


######################################################################
##脚本结束处理标志(模板)
######################################################################
_exit 0;
