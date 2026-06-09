#!/usr/bin/env bash
######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：2026-06-09
##修改内容：磐维慢SQL告警监控
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

#慢SQL查询
#sh /bi/app/realtime-jstorm/nljstorm jdbc toolconfig/jdbc_pw_mansql.yaml > ${FWDIR}/info/pw_mansql.info

#表头
req_str="<table border=\"1\" style=\"border-color: black;\" cellspacing=\"0\"><tr style=\"background-color: #C0C0C0;\"><td>pid</td><td>client_addr</td><td>query_cost(S)</td><td>query_start</td><td>now</td><td>sql</td></tr>"

#表体
req_str1_cnt=`cat ${FWDIR}/info/pw_mansql.info|grep '查询结果】'|wc -l`
req_str1=`cat ${FWDIR}/info/pw_mansql.info|grep '查询结果】'|awk -F '查询结果】' '{print $2}'|awk -F '|' '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td><td>"$6"</td></tr>"}'`
if [[ ${req_str1_cnt} -eq 0 ]]; then
    echo "["`date +"%Y-%m-%d %H:%M:%S"`"]慢SQL计数器为0，退出。"
    exit 1;
else
    echo "["`date +"%Y-%m-%d %H:%M:%S"`"]慢SQL计数器 ${req_str1_cnt}"
fi

#表结尾
echo ${req_str}${req_str1}"</table>" > ${FWDIR}/info/pw_mansql_send_data.info
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]邮件内容 `cat ${FWDIR}/info/pw_mansql_send_data.info`"

#标题，一分钟一次，分钟级别
subject="标签管理平台-慢SQL监控"`date '+%Y-%m-%dX%H:%M'`
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]邮件标题 ${subject}"
exit 1;

#邮件发送
retrycnt=0
while [[ ${retrycnt} -lt 1 ]]
do
  #send email
  sh /bi/app/realtime-jstorm/nljstorm send_email toolconfig/send_pw_mansql_139email.yaml --subject "${subject}"
  if [[ $? -eq 0 ]]; then
    echo "send mail success"
    break
  else
    echo "send mail fail, retry"
  fi
  let 'retrycnt+=1'
  sleep 3
done
