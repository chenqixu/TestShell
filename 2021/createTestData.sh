#!/usr/bin/env bash

###############################
##参数设置
###############################
#路径
FWDIR="$(cd `dirname $0`;pwd)"
#引入工具类
TOOL_PATH=${FWDIR}/../utils/
. $TOOL_PATH/tool.func

fun_start;
>$FWDIR/data/test.dat;
for i in {0..1000}; do echo $i >> $FWDIR/data/test.dat; done
fun_stopAndGet;
