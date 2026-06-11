#!/usr/bin/env bash
######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：2026-06-11
##修改内容：磐维分区个数监控、表大小膨胀监控
##修改人员：cqx
#####################################################


######################################################################
##参数设置
######################################################################
##判断系统是windows还是Linux
system_name=`uname`
##路径
FWDIR="$(cd `dirname $0`;pwd)"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]路径 ${FWDIR}"

#磐维分区个数查询
#sh /bi/app/realtime-jstorm/nljstorm jdbc toolconfig/jdbc_pw_partionssql.yaml > ${FWDIR}/info/pw_partionssql.info
#表头
req_str="<table border=\"1\" style=\"border-color: black;\" cellspacing=\"0\"><tr style=\"background-color: #C0C0C0;\"><td>table_name</td><td>partion cnt</td></tr>"
#表体
req_str1=`cat ${FWDIR}/info/pw_partionssql.info|grep '查询结果】'|awk -F '查询结果】' '{print $2}'|awk -F '|' '{print "<tr><td>"$1"</td><td>"$2"</td></tr>"}'`
#表结尾
echo "<h2>磐维分区个数查询</h2>"${req_str}${req_str1}"</table>" > ${FWDIR}/info/pw_tabalesql_send_data.info

#磐维表大小膨胀查询
#sh /bi/app/realtime-jstorm/nljstorm jdbc toolconfig/jdbc_pw_nopartionssql.yaml > ${FWDIR}/info/pw_nopartionssql.info
#表头
req_a_str="<table border=\"1\" style=\"border-color: black;\" cellspacing=\"0\"><tr style=\"background-color: #C0C0C0;\"><td>table_name</td><td>table_size(MB)</td><td>table_rows</td><td>row_per_size</td></tr>"
#表体
req_a_str1=`cat ${FWDIR}/info/pw_nopartionssql.info|grep '查询结果】'|awk -F '查询结果】' '{print $2}'|awk -F '|' '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td></tr>"}'`
#表结尾
echo "<h2>磐维表大小膨胀查询</h2>"${req_a_str}${req_a_str1}"</table>" >> ${FWDIR}/info/pw_tabalesql_send_data.info
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]邮件内容 `cat ${FWDIR}/info/pw_tabalesql_send_data.info`"

#标题，一天一次
subject="标签管理平台-表监控"`date '+%Y-%m-%dX%H:%M'`
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]邮件标题 ${subject}"
exit 1;

#邮件发送
retrycnt=0
while [[ ${retrycnt} -lt 5 ]]
do
  #send email
  sh /bi/app/realtime-jstorm/nljstorm send_email toolconfig/send_pw_tablesql_139email.yaml --subject "${subject}"
  if [[ $? -eq 0 ]]; then
    echo "send mail success"
    break
  else
    echo "send mail fail, retry"
  fi
  let 'retrycnt+=1'
  sleep 15
done
