#!/usr/bin/env bash
######################################################################
##参数
######################################################################
if [ $# -ne 2 ]; then
  echo "[ERROR] 参数个数不足, 你需要输入 [版本] 以及 [应用名称] .";
  exit 1;
fi
#paramer
v_tag=$1
v_app_name=$2
v_date=`date "+%Y%m%d"`
v_build_path=`pwd`"/.."
echo "----------------------------------打印参数信息-----------------------------"
echo "版本：${v_tag}"
echo "应用名称：${v_app_name}"
echo "时间：${v_date}"
echo "路径：${v_build_path}"


######################################################################
##检查备份
######################################################################
function checkback() {
echo "检查备份,步骤1,命令: ls ${v_build_path}/webapp/|grep ${v_app_name}${v_date}|wc -l"
v_checkback=`ls ${v_build_path}/webapp/|grep ${v_app_name}${v_date}|wc -l`
echo "检查备份,检查结果: ${v_checkback}"
}


######################################################################
##备份数据
######################################################################
function back() {
echo "备份数据,步骤1,命令: 判断检查备份的结果是否为0"
if [[ ${v_checkback} -eq 0 ]]; then
  echo "备份数据,步骤2,命令: cp -r ${v_build_path}/webapp/${v_app_name} ${v_build_path}/webapp/${v_app_name}${v_date}"
  cp -r ${v_build_path}/webapp/${v_app_name} ${v_build_path}/webapp/${v_app_name}${v_date}
else
  echo "不需要要备份，今天已经备份过，一天只需要备份一次"
fi
}


######################################################################
##检查标签
######################################################################
function checktag() {
echo "检查标签,步骤1,命令: ls ${v_build_path}/update/|grep ${v_app_name}-${v_tag}.war|wc -l"
v_checktag=`ls ${v_build_path}/update/|grep ${v_app_name}-${v_tag}.war|wc -l`
echo "检查标签,检查结果: ${v_checktag}"
}


######################################################################
##解压
######################################################################
function decompression() {
if [ ${v_checktag} -eq 1 ]; then
  echo "解压,步骤1,命令: rm -rf ${v_build_path}/webapp/${v_app_name}"
  rm -rf ${v_build_path}/webapp/${v_app_name}
  echo "解压,步骤2,命令: unzip -q ${v_build_path}/update/${v_app_name}-${v_tag}.war -d ${v_build_path}/webapp/${v_app_name}/"
  unzip -q ${v_build_path}/update/${v_app_name}-${v_tag}.war -d "${v_build_path}/webapp/${v_app_name}/"

  #rm old jar
  echo "解压,步骤3,命令: rm -f ${v_build_path}/webapp/${v_app_name}/WEB-INF/lib/ojdbc14-10.2.0.4.0.jar"
  rm -f ${v_build_path}/webapp/${v_app_name}/WEB-INF/lib/ojdbc14-10.2.0.4.0.jar

  #cp config/lib
  echo "解压,步骤4,命令: cp config/lib,cmd: cp -r ${v_build_path}/update/config/${v_app_name}/WEB-INF/ ${v_build_path}/webapp/${v_app_name}/"
  cp -r ${v_build_path}/update/config/${v_app_name}/WEB-INF/ ${v_build_path}/webapp/${v_app_name}/

  return 1
else
  echo "需要更新的包没有找到，无法解压"
  return 2
fi
}


###############################
#main
###############################
echo "----------------------------------执行-----------------------------"
#检查备份
checkback
#备份数据
back
#检查需要处理的jar、war包
checktag
#解压
decompression
