#!/usr/bin/env bash
#############################################################################################
##程序描述：切分文件，循环导入GSDB不同节点
##实现功能：
##运行周期：
##创建作者：
##创建日期：2021-05-17
#############################################################################################

###############################
#检查
###############################
#参数个数检查
if [[ $# -ne 1 ]]; then
    echo "【ERROR】 there is no enough args, you need input [filePath] ."
    exit -1
fi

filePath=$1
echo "filePath:${filePath}"
gsdb_array=(GSDB1 GSDB2 GSDB3 GSDB4 GSDB5 GSDB6 GSDB7 GSDB8 GSDB9 GSDB10 GSDB11 GSDB12);

v_dir_name=`dirname ${filePath}`
v_base_name=`basename ${filePath}`
v_split_path="${v_dir_name}/${v_base_name}_split"
echo "mkdir -p ${v_split_path}"
mkdir -p ${v_split_path}
echo "cd ${v_split_path}"
cd ${v_split_path}
#统计记录数
lineNum=`cat ${filePath} | wc -l`;
#计算如何平均分配到所有节点
gsdbSize=${#gsdb_array[*]}
tmp_avgNum=$[$lineNum/$gsdbSize]
tmp_avgNum_mantissa=$[tmp_avgNum/30]
avgNum=$[tmp_avgNum+tmp_avgNum_mantissa]
echo "lineNum: ${lineNum}, gsdbSize : ${gsdbSize}, tmp_avgNum: ${tmp_avgNum}, tmp_avgNum_mantissa: ${tmp_avgNum_mantissa}, avgNum:${avgNum}"

echo "split -${avgNum} -d ${filePath}"
split -${avgNum} -d ${filePath}
i=0
for v_tmp in `ls ${v_split_path}`
do
    tmp_line=` cat ${v_split_path}/${v_tmp}|wc -l`
    echo "${i} ${v_split_path}/${v_tmp} ${gsdb_array[${i}]} ${tmp_line}"
    let 'i+=1'
    if [[ $i -eq ${#gsdb_array[*]} ]]; then
        i=0
    fi
done
#清理
echo "rm -rf ${v_split_path}"
rm -rf ${v_split_path}