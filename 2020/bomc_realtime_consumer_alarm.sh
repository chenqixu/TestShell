#!/bin/sh

######################################################################
##部署主机：需要配置在有kafka消费者查询脚本的主机上
######################################################################
######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：20200927
##修改内容：新建
##修改人员：cqx
#####################################################

##常量设置，判断消费者是否正常
NORMAL_FLAG=0;

##消费者信息配置，依次为
##位置信令融合应用消费者：MID_POSITION_RESUME_KFK_J，有2个话题，nmc_tb_lte_s1mme_new和nmc_tb_mc_cdr
##用户实时位置消费者：REALTIME_LOCATION_J_ALTIBASE
##用户实时轨迹消费者: POSITION_SCENE_ALTIBASE
##偏移量阈值
offset_common=300000000
offset_arr=($offset_common $offset_common $offset_common $offset_common $offset_common 50000000);
##临时排除
exclusive_consumers_arr=(REALTIME_LOCATION_J_TT POSITION_SCENE_J);
##消费者id
consumers_arr=(MID_POSITION_RESUME_KFK_J REALTIME_LOCATION_J_ALTIBASE POSITION_SCENE_ALTIBASE REALTIME_LOCATION_J_TT POSITION_SCENE_J http-digitchina-tt-group);
##消费者个数
consumers_alarmcount_arr=(218 140 140 140 140 140);

##消息中心环境变量配置
export KAFKA_OPTS="-Djava.security.auth.login.config=/bi/sysapp/kafka/etc/test.conf";
KAFKA_HOME=/bi/sysapp/kafka;
KAFKA_BROKER=10.48.137.217:9092;

##日志信息，简单处理每次覆盖日志，避免BOMC异常
monitor_path=/home/edc_base/monitor/bomc_log/
logFile=${monitor_path}/realtimeLog/realtime-monitor-alarm.log;
##获取消息中心消费者当前状态，输入参数为消费者数组下标ID，输出消费者当前消息中心指标信息文件
function get_consumer_info() {
        local consumer=$1;
        ${KAFKA_HOME}/bin/kafka-consumer-groups.sh --bootstrap-server ${KAFKA_BROKER} --group ${consumer} --describe --command-config ${KAFKA_HOME}/config/consumergroups.properties --new-consumer | grep -v 'CURRENT-OFFSET' | grep -v '^$' > ${monitor_path}/query-kafka-data/${consumer}.log
}

##判断消费者偏移量状态，输入参数为消费者数组下标ID，输出偏移量是否正常标志
function judge_offset_status() {
        local consumer_id=$1;
        local consumer=$2;
        local offset_limit=${offset_arr[${consumer_id}]};
        consumer_offset=`awk '{print $5}' ${monitor_path}/query-kafka-data/${consumer}.log | awk '{totalLag += $1} END {print totalLag}'`;
        result_flag=0
        if [ ${consumer_offset} -ge ${offset_limit} ]; then
                result_flag=1;
        fi;
        return ${result_flag};
}

##判断消费者是否存在状态，输入参数为消费者数组下标ID，输出消费者是否不存在标志
function judge_exist_status() {
        local consumer=$1;
        result_flag=`grep "does not exist" ${monitor_path}/query-kafka-data/${consumer}.log | wc -l`;
        return ${result_flag};
}

##判断消费者是否重分布状态，输入参数为消费者数组下标ID，输出消费者是否重分布标志
function judge_balance_status() {
        local consumer=$1;
        result_flag=`grep "rebalancing" ${monitor_path}/query-kafka-data/${consumer}.log | wc -l`;
        return ${result_flag};
}

##判断消费者个数
function judge_consumer_count() {
        local consumer=$1;
        local check_count=$2;
        consumer_count=`cat ${monitor_path}/query-kafka-data/${consumer}.log | wc -l`;
        result_flag=0;
        #不等于
        if [[ consumer_count -ne check_count ]]; then
                result_flag=1;
        fi
        return ${result_flag};
}

#不知道这里为什么要清理日志
#>${logFile};
##主函数处理逻辑 START
#for consumer in ${consumers_arr[@]}
echo `date +%Y-%m-%d\ %H:%M:%S`, [INFO] 开始逐个判断位置基础消费者是否正常, s1mme,mc_cdr-位置信令融合应用消费者, 位置信令融合应用话题-用户实时位置消费者, 位置信令融合应用话题-用户实时轨迹消费者 >> ${logFile};
error_result=0;
for consumer_id in "${!consumers_arr[@]}";
do
        consumer=${consumers_arr[${consumer_id}]};
        consumer_alarmcount=${consumers_alarmcount_arr[${consumer_id}]};
        consumer_offset_limit=${offset_arr[${consumer_id}]};
        echo `date +%Y-%m-%d\ %H:%M:%S`, [INFO] 开始判断消费者:${consumer},积压判断${consumer_offset_limit},消费者个数${consumer_alarmcount}是否正常 >> ${logFile};

        ##添加消费者异常剔除模块，在特殊情况下进行跳过避免频繁告警，简单判断模糊匹配消费者名称包含于数组中
        if [[ ${exclusive_consumers_arr[@]} =~ ${consumer} ]]; then
                echo `date +%Y-%m-%d\ %H:%M:%S`, [WARN] 消费者:${consumer}存在于异常剔除配置数组中, 不进行消费者校验, 输出正常指标 >> ${logFile};
                continue;
        fi;

        ##获取消息中心状态信息
        get_consumer_info ${consumer};

        judge_exist_status ${consumer};
        if [ $? -ne ${NORMAL_FLAG} ]; then
                echo `date +%Y-%m-%d\ %H:%M:%S`, [ERROR] 消费者:${consumer}不存在异常, 请安排稽核 >> ${logFile};
                let error_code=10**${consumer_id};
                let error_result=${error_result}+${error_code};
                continue;
        fi;

        judge_balance_status ${consumer};
        if [ $? -ne ${NORMAL_FLAG} ]; then
                echo `date +%Y-%m-%d\ %H:%M:%S`, [ERROR] 消费者:${consumer}重分布异常, 请安排稽核 >> ${logFile};
                let error_code=10**${consumer_id};
                let error_result=${error_result}+${error_code};
                continue;
        fi;

        judge_offset_status ${consumer_id} ${consumer};
        if [ $? -ne ${NORMAL_FLAG} ]; then
                echo `date +%Y-%m-%d\ %H:%M:%S`, [ERROR] 消费者:${consumer}数据处理积压异常, 请安排稽核 >> ${logFile};
                let error_code=10**${consumer_id};
                let error_result=${error_result}+${error_code};
                continue;
        fi;

        judge_consumer_count ${consumer} ${consumer_alarmcount};
        if [ $? -ne ${NORMAL_FLAG} ]; then
                echo `date +%Y-%m-%d\ %H:%M:%S`, [ERROR] 消费者:${consumer}消费个数不正常,不等于${consumer_alarmcount}, 请安排稽核 >> ${logFile};
                let error_code=10**${consumer_id};
                let error_result=${error_result}+${error_code};
                continue;
        fi;

        ##所有异常校验均正常，输出正常日志
        echo `date +%Y-%m-%d\ %H:%M:%S`, [INFO] 消费者:${consumer}运行情况正常 >> ${logFile};
done;
echo `date +%Y-%m-%d\ %H:%M:%S`, [INFO] 所有消费者状态查询完成，输出异常指标编码 >> ${logFile};
#bomc监控状态
echo ${error_result} > ${monitor_path}/realtimekafkaMonitor.txt;
echo ${error_result} > /tmp/bomc_file/realtimekafkaMonitor.txt
#不告警
#echo 0 > /tmp/bomc_file/realtimekafkaMonitor.txt
#自动重启，1:restart 2:no restart
sh /home/edc_base/monitor/autorestart/autorestart.sh 1 ${offset_common} >> /home/edc_base/monitor/autorestart/lautorestart.log
##主函数处理逻辑 END
exit;