#!/usr/bin/env bash
#############################################################################################
##程序描述：家宽上报HDFS工具脚本
##实现功能：生成某周期目录，上传000000_0文件；生成完成标志；查看
##运行周期：
##创建作者：
##创建日期：2020-06-18
#############################################################################################

###############################
#菜单
###############################
function menu() {
    clear
    echo
    echo -e "###############################"
    echo -e "##\tmenu"
    echo -e "###############################"
    echo -e "##\tM|m. [yyyyMMddHH] mkdir path & put 000000_0"
    echo -e "##\tL|l. [yyyyMMddHH] ls path"
    echo -e "##\tO|o. [yyyyMMddHHmm] [type] put yyyyMMddHHmm.ok to type"
    echo -e "##\tC|c. [yyyyMMddHHmm] [type] put yyyyMMddHHmm.complete to type"
    echo -e "##\tD|d. [yyyyMMddHH|yyyyMMddHHmm] delete yyyyMMddHH OR yyyyMMddHHmm"
    echo -e "##\tH|h. show help"
    echo -e "##\tQ|q|quit|exit Exit menu"
    #-en 选项会去掉末尾的换行符，这让菜单看起来更专业一些
#    echo -en "\t\tEnter option:"
}

###############################
#时间格式yyyyMMddHH
###############################
function lsdir() {
    date=$1
    date_len=`echo ${date}|wc -L`
    if [[ date_len -ne 10 ]]; then
        echo "hdfs dfs -ls /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/*/*|grep rw|awk '{print \$8}'"
        hdfs dfs -ls /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/*/*|grep rw|awk '{print $8}'
    else
        echo "hdfs dfs -ls /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}*/*|grep rw|awk '{print \$8}'"
        hdfs dfs -ls /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}*/*|grep rw|awk '{print $8}'
    fi
}

function mp() {
    date=$1
    date_len=`echo ${date}|wc -L`
    if [[ date_len -ne 10 ]]; then
        echo "【ERROR】value：${date}，length must be yyyyMMddHH"
    else
        for i in 00 15 30 45; do
            echo "hdfs dfs -mkdir -p /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}${i}/nat"
            echo "hdfs dfs -mkdir -p /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}${i}/notnat"
            echo "touch 000000_0"
            echo "hdfs dfs -put 000000_0 /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}${i}/nat"
            echo "hdfs dfs -put 000000_0 /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}${i}/notnat"
            echo "rm -f 000000_0"
            hdfs dfs -mkdir -p /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}${i}/nat
            hdfs dfs -mkdir -p /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}${i}/notnat
            touch 000000_0
            hdfs dfs -put 000000_0 /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}${i}/nat
            hdfs dfs -put 000000_0 /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}${i}/notnat
            rm -f 000000_0
        done
    fi
}

function ok() {
    if [[ $# -ne 2 ]]; then
        echo "【ERROR】 there is no enough args, you need input date{yyyyMMddHHmm} and type{nat|notnat}."
    else
        create $1 $2 "ok"
    fi
}

function complete() {
    if [[ $# -ne 2 ]]; then
        echo "【ERROR】 there is no enough args, you need input date{yyyyMMddHHmm} and type{nat|notnat}."
    else
        create $1 $2 "complete"
    fi
}

function create() {
    date=$1
    type=$2
    flag=$3
    date_len=`echo ${date}|wc -L`
    if [[ date_len -ne 12 ]]; then
        echo "【ERROR】value：${date}，length must be yyyyMMddHHmm"
    else
        echo "touch ${date}.${flag}"
        echo "hdfs dfs -put ${date}.${flag} /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}/${type}/"
        echo "rm -f ${date}.${flag}"
        touch "${date}.${flag}"
        hdfs dfs -put "${date}.${flag}" /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}/${type}/
        rm -f "${date}.${flag}"
    fi
}

function delete() {
    date=$1
    date_len=`echo ${date}|wc -L`
    if [[ date_len -eq 10 ]]; then
        echo "hdfs dfs -rm -r -skipTrash /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}*"
        hdfs dfs -rm -r -skipTrash /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}*
    elif [[ date_len -eq 12 ]]; then
        echo "hdfs dfs -rm -r -skipTrash /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}"
        hdfs dfs -rm -r -skipTrash /user/bdoc/20/services/hdfs/17/yz/bigdata/if_upload_hb_netlog/${date}
    else
        echo "【ERROR】 there is no enough args, you need input date{yyyyMMddHH} or date{yyyyMMddHHmm}."
    fi
}

#显示菜单
menu

#Backspace键并未删除光标左面那个字符，仅仅显示^H，而DEL键完成了删除操作
stty erase '^H'

while true
do
  echo ""
  echo -en "\033[31mYour Choice >>> \033[0m"

  read CHOICE PARA2 PARA3
  case $CHOICE in
    M|m)
       mp $PARA2;
       ;;
    L|l)
       lsdir $PARA2;
       ;;
    O|o)
       ok $PARA2 $PARA3;
       ;;
    C|c)
       complete $PARA2 $PARA3;
       ;;
    D|d)
       delete $PARA2;
       ;;
    H|h)
       menu
       ;;
    Q|q|quit|exit) exit 0
       ;;
    *) echo -e "\tUnknown Choice!"
       ;;
  esac
done