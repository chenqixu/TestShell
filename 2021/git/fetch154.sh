#!/usr/bin/expect
cd /bi/user/cqx/data/git/205/
spawn git fetch repo154 develop:repo154
expect "Username"
send "chenqixu\n"
expect "Password"
send "Cqx123!!\n"
expect eof