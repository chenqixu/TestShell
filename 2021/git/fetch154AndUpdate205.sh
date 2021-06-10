#!/usr/bin/env bash
########################
##cqx add 每5分钟同步一次154的git代码到205
#*/5 * * * * /bi/user/cqx/data/git/fetch154AndUpdate205.sh
########################

########################
#初始化
#close 205的develop分支到/bi/user/cqx/data/git/205/目录下
#git clone -b develop http://10.1.8.205:7080/real-time/etl-jstorm.git /bi/user/cqx/data/git/205/etl-jstorm.git
#git clone -b develop http://10.1.8.205:7080/real-time/realtime-jstorm.git /bi/user/cqx/data/git/205/realtime-jstorm.git

#添加154的URL作为新远程仓库，命名为repo154
#cd /bi/user/cqx/data/git/205/etl-jstorm.git
#git remote add repo154 http://10.1.8.154:7080/BI-BIGDATA/etl-jstorm.git
#cd /bi/user/cqx/data/git/205/realtime-jstorm.git
#git remote add repo154 http://10.1.8.154:7080/BI-BIGDATA/realtime-jstorm.git
########################

###############################
##全局变量
###############################
git_name=""

###############################
##判断远程库是否存在，不存在则添加
###############################
function remoteCheck() {
cnt=`git remote -v|grep repo154|wc -l`
if [[ ${cnt} -gt 0 ]]; then
    echo "远程库存在"
else
    echo "远程库不存在，需要初始化"
    git remote add repo154 http://10.1.8.154:7080/BI-BIGDATA/${git_name}
fi
}

###############################
##将154的develop分支获取到205并创建分支为repo154
###############################
function fetch154() {
expect <<EOF
cd /bi/user/cqx/data/git/205/${git_name}
spawn git fetch repo154 develop:repo154
expect "Username"
send "chenqixu\n"
expect "Password"
send "Cqx123!!\n"
expect eof
EOF
}

###############################
##推送到远程205仓库
###############################
function push205() {
expect <<EOF
cd /bi/user/cqx/data/git/205/${git_name}
spawn git push
expect "Username"
send "chenqx\n"
expect "Password"
send "Cqx123456\n"
expect eof
EOF
}

function fetch154AndUpdate205() {
git_name=$1
echo "====开始处理${git_name}===="
cd /bi/user/cqx/data/git/205/${git_name}
#切换到需要合并的分支
git checkout develop
#判断远程库是否存在，不存在则添加
remoteCheck
#将154的develop分支获取到205并创建分支为repo154
fetch154
#切换到repo154分支
git checkout repo154
#把当前分支变基到develop分支
git rebase develop
#切换到develop分支
git checkout develop
#合并变基内容
git merge repo154
#推送到远程205仓库
push205
#删除repo154分支
git branch -d repo154
echo "====处理${git_name}完成===="
}

fetch154AndUpdate205 "etl-jstorm.git"
fetch154AndUpdate205 "realtime-jstorm.git"