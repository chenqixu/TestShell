#!/bin/sh
#####################################################
##程序描述：校验上个步骤是否执行成功，如果不成功则需要进行重试
##实现功能：校验上个步骤是否执行成功，如果不成功则需要进行重试
##运行周期：无
##创建作者：cqx
##创建日期：2023-03-03
#####################################################
#####################################################
##版本信息：版本注释，描述修改内容：
#####################################################
##版本号：
##修改日期：
##修改内容：
##修改人员：
#####################################################

retrycnt=0
while [[ ${retrycnt} -lt 3 ]]
do
  rm /bi/user/cqx/data/ax.txt
  if [[ $? -eq 0 ]]; then
    echo "ok"
    break
  else
    echo "no"
  fi
  let 'retrycnt+=1'
  sleep 3
done