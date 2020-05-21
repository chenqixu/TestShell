#!/usr/bin/env bash
#############################################################################################
##程序描述：批量调用《家宽六期访问日志上报预处理脚本》
##实现功能：通过传入的日期和分钟，循环调用脚本
##运行周期：一天
##创建作者：
##创建日期：2020-05-21
#############################################################################################

###############################
#说明
###############################
#循环生成1天的task_id
#103428376707@2020052000000000
#103428376707@2020052000150000
#103428376707@2020052000300000
#103428376707@2020052000450000
#command:
#sh qry_hbrand_report_j.sh 103428376707@2020052000150000 3 4 'set mapreduce.job.queuename=root.bdoc.renter_1.renter_20.dev_20;' 'set hadoop.security.bdoc.access.id=2ac785475bf34c10bcb0;' 'set hadoop.security.bdoc.access.key=7c48264803431b40ca62f3c38f89ef33a5f14cdd;'

###############################
#方法
###############################
function lenCheck() {
    str=${1}
    len=${2}
    name=${3}
    date_len=`echo ${str}|wc -L`
    if [[ date_len -ne ${len} ]]; then
        echo "【ERROR】${name} value：${str}，length must be ${len}"
        exit -1
    fi
}

###############################
#检查
###############################
#参数个数检查
if [[ $# -ne 2 ]]; then
    echo "【ERROR】 there is no enough args, you need input date{yyyymmdd} and minute."
    exit -1
fi
date=${1}
minute=${2}
echo "【date】${date}【minute】${minute}"
#参数长度校验
lenCheck ${date} 8 "date"
lenCheck ${minute} 2 "minute"

###############################
#脚本正式内容
###############################
exec_path=`pwd`
id="103428376707@${date}"
end="0000"
shell_name="${exec_path}/qry_hbrand_report_j.sh"
shell_arg_queuename="set mapreduce.job.queuename=root.bdoc.renter_1.renter_20.dev_20;"
shell_arg_bdocid="set hadoop.security.bdoc.access.id=2ac785475bf34c10bcb0;"
shell_arg_bdockey="set hadoop.security.bdoc.access.key=7c48264803431b40ca62f3c38f89ef33a5f14cdd;"
shell_arg=" 3 4 ${shell_arg_queuename} ${shell_arg_bdocid} ${shell_arg_bdockey}"
#这里由于00跑过了，所以删掉00
for hour in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 ; do
#    echo "hour : ${hour}"
#    for minute in 00 14 30 45 ; do
        task_id="${id}${hour}${minute}${end}"
        cmd="sh ${shell_name} ${task_id} 3 4 \"${shell_arg_queuename}\" \"${shell_arg_bdocid}\" \"${shell_arg_bdockey}\""
        echo "【cmd】${cmd}"
        sh ${shell_name} "${task_id}" 3 4 "${shell_arg_queuename}" "${shell_arg_bdocid}" "${shell_arg_bdockey}"
#    done
done
