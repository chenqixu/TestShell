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
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]路径=${FWDIR}"
##是否生产模式
is_sc="false"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]是否生产模式=${is_sc}"
##慢SQL发送计数器
send_mail_max=5

#读取文件里的计数器
send_mail_cnt=`cat ${FWDIR}/info/pw_mansql.cnt`
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]发送邮件计数器为=${send_mail_cnt}"
let 'send_mail_cnt+=1'
echo ${send_mail_cnt} > ${FWDIR}/info/pw_mansql.cnt

#慢SQL查询
if [[ "${is_sc}" = "true" ]]; then
    sh /bi/app/realtime-jstorm/nljstorm jdbc toolconfig/jdbc_pw_mansql.yaml > ${FWDIR}/info/pw_mansql.info
fi

#表头
req_str="<table border=\"1\" style=\"border-color: black;\" cellspacing=\"0\"><tr style=\"background-color: #C0C0C0;\"><td>pid</td><td>client_addr</td><td>query_cost(S)</td><td>query_start</td><td>now</td><td>sql</td></tr>"

#表体
req_str1_cnt=`cat ${FWDIR}/info/pw_mansql.info|grep '查询结果】'|wc -l`
req_str1=`cat ${FWDIR}/info/pw_mansql.info|grep '查询结果】'|awk -F '查询结果】' '{print $2}'|awk -F '|' '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td><td>"$6"</td></tr>"}'`
if [[ ${req_str1_cnt} -eq 0 ]]; then
    echo "["`date +"%Y-%m-%d %H:%M:%S"`"]慢SQL计数器=0"
else
    echo "["`date +"%Y-%m-%d %H:%M:%S"`"]慢SQL计数器=${req_str1_cnt}"
    #表结尾，追加模式
    echo "<h2>慢SQL个数：${req_str1_cnt}</h2>"${req_str}${req_str1}"</table>" >> ${FWDIR}/info/pw_mansql_send_data.info
    echo "["`date +"%Y-%m-%d %H:%M:%S"`"]邮件内容 `cat ${FWDIR}/info/pw_mansql_send_data.info`"
fi

#判断是否有内容要发邮件
content_cnt=`cat ${FWDIR}/info/pw_mansql_send_data.info|grep "慢SQL个数"|wc -l`
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]是否有内容要发邮件=${content_cnt}"

#判断发送邮件计数器
if [[ ${send_mail_cnt} -ge ${send_mail_max} ]]; then
    if [[ ${content_cnt} -gt 0 ]]; then
        #发邮件
        #标题，一分钟一次，分钟级别
        subject="标签管理平台-慢SQL监控"`date '+%Y-%m-%dX%H:%M'`
        echo "["`date +"%Y-%m-%d %H:%M:%S"`"]邮件标题 ${subject}"
        #exit 1;

        #邮件发送
        retrycnt=0
        while [[ ${retrycnt} -lt 5 ]]
        do
            #send email
            if [[ "${is_sc}" = "true" ]]; then
                sh /bi/app/realtime-jstorm/nljstorm send_email toolconfig/send_pw_mansql_139email.yaml --subject "${subject}"
            fi
            #邮件发送结果判断
            if [[ $? -eq 0 ]]; then
                echo "["`date +"%Y-%m-%d %H:%M:%S"`"]send mail success"
                #发送成功，文件内容清零
                echo "["`date +"%Y-%m-%d %H:%M:%S"`"]发送成功，文件内容清零"
                echo "" > ${FWDIR}/info/pw_mansql_send_data.info
                break
            else
                echo "["`date +"%Y-%m-%d %H:%M:%S"`"]send mail fail, retry"
            fi
            #邮件发送失败，计数器+1，重试，间隔x秒
            let 'retrycnt+=1'
            sleep 3
        done
    fi

    #发送邮件计数器清零
    echo "["`date +"%Y-%m-%d %H:%M:%S"`"]发送邮件计数器清零"
    echo "0" > ${FWDIR}/info/pw_mansql.cnt
fi

