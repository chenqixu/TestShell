#!/usr/bin/env bash
#############################################################################################
##程序描述：安装JStorm
##实现功能：安装JStorm，准备工作：在第一台弄好可用的jdk和已经可以启动的jstorm，然后打包，配置好环境变量
##运行周期：
##创建作者：
##创建日期：2020-09-03
#############################################################################################

###############################
#主机列表
###############################
ips_dev="10.1.8.204"
ips_sc="10.45.179.119
10.45.179.120
10.45.179.121
10.45.179.122
10.45.179.123
10.45.179.124"
ips=""

###############################
#用户密码
###############################
user_dev="edc_base"
user_sc="jstorm"
passwd_dev="fLyxp1s*"
passwd_sc="k+R40NHy"
i_user=""
i_passwd=""

###############################
#判断开发还是生产
###############################
i_host=`hostname -i`
if [[ ${i_host} =~ "10.1.8." ]]
then
    echo "===is dev==="
    ips=${ips_dev}
    i_user=${user_dev}
    i_passwd=${passwd_dev}
else
    echo "===is sc==="
    ips=${ips_sc}
    i_user=${user_sc}
    i_passwd=${passwd_sc}
fi

###############################
#拷贝文件
###############################
function f_scp() {
scp_file=${1}
scp_ip=${2}
echo "scp_ip : ${scp_ip} , scp_file : ${scp_file}"
sshpass -p "${i_passwd}" scp ${scp_file} ${i_user}@${scp_ip}:/home/${i_user}/
echo "scp_file result : ${?}"
}

###############################
#远程执行命令
###############################
function f_ssh() {
ssh_cmd=${1}
scp_ip=${2}
echo "scp_ip : ${scp_ip} , ssh_cmd : ${ssh_cmd}"
sshpass -p "${i_passwd}" ssh -o StrictHostKeychecking=no -l ${i_user} ${scp_ip} "${ssh_cmd}"
f_result=${?}
echo "ssh_cmd result : ${f_result}"
return ${f_result}
}

###############################
#main
###############################
for ip in ${ips}
do
    #检查是否有jstorm目录
    f_ssh "test -d /home/${i_user}/edc-app/jstorm-2.1.1/" "${ip}"
    check_jstorm=${?}
    #检查是否有jdk目录
    f_ssh "test -d /home/${i_user}/jdk/jdk1.8.0_73/" "${ip}"
    check_jdk=${?}
    #如果2者存在其一,就进行下个循环
    if [[ ${check_jstorm}=0 ]] || [[ ${check_jdk}=0 ]]; then
        echo "${ip} continue"
        continue
    fi
    #scp
    f_scp "jstorm_jdk.zip" "${ip}"
    #解压
    f_ssh "unzip -qo /home/${i_user}/jstorm_jdk.zip -d /home/${i_user}/" "${ip}"
    #删除
    f_ssh "rm -f /home/${i_user}/jstorm_jdk.zip" "${ip}"
    #scp环境变量
    f_scp ".bash_profile" "${ip}"
done
