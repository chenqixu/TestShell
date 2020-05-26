#!/usr/bin/env bash
#############################################################################################
##程序描述：文件按小时删除
##实现功能：文件按小时删除
##运行周期：一天
##创建作者：
##创建日期：2020-05-25
#############################################################################################

###############################
#检查
###############################
#参数个数检查
if [[ $# -ne 2 ]]; then
    echo "【ERROR】 there is no enough args, you need input [yyyymmdd] && [rm hour]."
    exit -1
fi
rm_date=${1}
rm_hour=${2}
rm_path="/bi/databackup/if_upload_hb_netlog/${rm_date}/"
rm_flag="*${rm_date}${rm_hour}"
if [[ ! -d ${rm_path} ]]; then
    echo "【ERROR】${rm_path} is not find."
    exit -1
fi
echo "【params】${rm_path} ${rm_flag}"
#分钟十位
for hour in 0 1 2 3 4 5 ; do
    #分钟个位
    for min in {0..9} ; do
        #秒十位
        for second in 0 1 2 3 4 5 ; do
            cmd="rm -f ${rm_path}${rm_flag}${hour}${min}${second}*"
            echo "【cmd】${cmd}"
#            rm -f rm -f ${rm_path}${rm_flag}${hour}${min}${second}*
        done
    done
done
cmd="du -shc ${rm_path}"
echo "【cmd】${cmd}"
#du -shc ${rm_path}