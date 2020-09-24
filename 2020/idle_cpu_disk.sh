#!/usr/bin/env bash
#############################################################################################
##程序描述：制造高CPU和高IO
##实现功能：在10.1.8.203上测试，idle_file_num填cpu的core即可，300000刚好1分钟多一点
##运行周期：
##创建作者：
##创建日期：2020-09-24
#############################################################################################

###############################
#看cpu的core
#more /proc/cpuinfo |grep processor|wc -l
###############################

###############################
#检查
###############################
#参数个数检查
if [[ $# -ne 3 ]]; then
    echo "【ERROR】 there is no enough args, you need input [idle_file_name] & [idle_file_num] & [idle_file_content_num]."
    exit -1
fi

###############################
#参数
###############################
#临时文件名
idle_file_name=${1}
idle_file_num=${2}
idle_file_content_num=${3}
#临时数据
tmp_content="2214|0596|11|038c00065b89be93|460020596548335|867681039514350|13459629256|C3DBA3C8|1|10.1.28.91|100.77.31.64|100.77.138.107|2152|2152|596F|761BA02|||6|CMNET||107|3458764533155465733|1554944254634|54087|1554944308721|18|22503||0||47582|139.9.55.249|8147|460|0|80082|2037005|||||53182|52710|1483|2223||||||0|0|0|0|0|0|35|75|0|0|82432|1394|1|0|1|139.9.55.249:8147/458b7082a1884b52b11ce848bb9dbb56_1?expire=1554944554&digest=d06b|Rtsp Client/2.0 HSWX|139.9.55.249|47582|47582|8147|8147|1|1|2958||||2019|04|11|08|58|||||||||535489|176|4202|411117856|13|0||||||"

function idle() {
    #要生成的临时文件
    tmp_file_no="${idle_file_name}${1}"
    echo "idle ${tmp_file_no}"

    #判断临时文件是否存在，存在则删除
    if [[ -f ${tmp_file_no} ]]; then
        echo "rm -f ${tmp_file_no}"
        rm -f ${tmp_file_no}
    fi

    #往临时文件里写入数据
    echo "cat data to ${tmp_file_no}..."
    for ((j=0; j<=${idle_file_content_num}; j++)) do
        echo ${tmp_content} >> ${tmp_file_no}
    done
}

###############################
#main
###############################
echo "idle_file_name : ${idle_file_name} , idle_file_num : ${idle_file_num} , idle_file_content_num : ${idle_file_content_num} ."
for ((i=0; i<=${idle_file_num}; i++)) do
    idle ${i} &
done
#等待并行任务完成
wait
