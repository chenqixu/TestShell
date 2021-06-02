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
##将154的develop分支获取到205并创建分支为repo154
###############################
function fetch154() {
git_name=$1
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
git_name=$1
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
cd /bi/user/cqx/data/git/205/${git_name}
#切换到需要合并的分支
git checkout develop
#将154的develop分支获取到205并创建分支为repo154
fetch154 ${git_name}
#切换到repo154分支
git checkout repo154
#把当前分支变基到develop分支
git rebase develop
#切换到develop分支
git checkout develop
#合并变基内容
git merge repo154
#推送到远程205仓库
push205 ${git_name}
#删除repo154分支
git branch -d repo154
}

fetch154AndUpdate205 "etl-jstorm.git"
fetch154AndUpdate205 "realtime-jstorm.git"