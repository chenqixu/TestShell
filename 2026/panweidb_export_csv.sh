#!/usr/bin/env bash
######################################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：v1.0
##修改日期：2026-06-11
##修改内容：磐维copy命令导出脚本
## 2个入参
## 入参1]执行的SQL文件（可以是本目录下的，也可以是完整路径）
## 入参2]导出文件（一定要完整路径）
##修改人员：cqx
##调用示例：./panweidb_export_csv.sh /bi/user/cqx/sql/panweidb_export1.sql /bi/user/cqx/data/1.csv
#####################################################


######################################################################
##参数设置
######################################################################
##判断系统是windows还是Linux
system_name=`uname`
##路径
FWDIR="$(cd `dirname $0`;pwd)"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]脚本执行路径=${FWDIR}"

##参数检查
if [ $# -ne 2 ]; then
  echo "你需要输入2个参数."
  echo "1] 执行的SQL文件（可以是本目录下的，也可以是完整路径）."
  echo "2] 导出文件（一定要完整路径）."
  exit 1
fi
exec_sql_file=$1
export_file=$2
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]执行的SQL文件=${exec_sql_file}"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]数据导出文件=${export_file}"
if [ ! -f ${exec_sql_file} ]; then
  echo "[exec_sql_file]${exec_sql_file} is not file."
  exit 1
fi
if [ ! -f ${export_file} ]; then
  echo "[export_file]${export_file} is not file."
  exit 1
fi

##清空导出文件
echo "">${export_file}

db_ip="10.1.4.8"
db_port=5432
db_name="subject"
db_username="subject"
db_password="H5ZRtF3f!qYycTkN"
escaped_var="${export_file//\//\\/}"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]db_ip=${db_ip}"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]db_port=${db_port}"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]db_name=${db_name}"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]db_username=${db_username}"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]导出路径替换=${escaped_var}"

sql="\COPY (`cat ${exec_sql_file}`) TO 'EXPORTPATH' WITH (FORMAT csv, HEADER true)"
echo ${sql} > ${exec_sql_file}.new1
sed "s/EXPORTPATH/${escaped_var}/g" ${exec_sql_file}.new1 > ${exec_sql_file}.new2
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]执行语句=`cat ${exec_sql_file}.new2`"

##密码提示
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]db_password=${db_password}"
##执行导出
#/bi/sysapp/apsaradb_for_gp_client_package/bin/psql -h ${db_ip} -p ${db_port} -d ${db_name} -U ${db_username} -f ${exec_sql_file}.new2
##结果统计
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]查看命令=cat ${export_file}|more"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]结果统计="`cat ${export_file}|wc -l`

rm ${exec_sql_file}.new1
rm ${exec_sql_file}.new2
