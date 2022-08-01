#!/usr/bin/env bash
#############################################################################################
##程序描述：ftp命令测试
##实现功能：
##运行周期：
##创建作者：
##创建日期：2022-08-01
#############################################################################################


###############################
##参数设置
###############################
#路径
FWDIR="$(cd `dirname $0`;pwd)"


###############################
##ls远程FTP服务器剩余文件
###############################
function ftpFromRemote() {
ftp -inv <<EOF
open ${1}
user ${2} ${3}
bin
ls ${4}
bye
EOF
}


###############################
##mget远程FTP服务器剩余文件
###############################
function ftpMget() {
ftp -in <<EOF
open ${1}
user ${2} ${3}
bin
lcd ${4}
cd ${5}
mget ${6}
bye
EOF
}


###############################
##main
###############################
ftpFromRemote 10.1.8.203 edc_base fLyxp1s* *.dat > ftp.log
cat ftp.log|grep .dat
echo "file total: "`cat ftp.log|grep .dat|wc -l`
rm -f ftp.log

ftpMget 10.1.8.203 edc_base fLyxp1s* ${FWDIR} /home/edc_base \*dat
rm -f *.dat