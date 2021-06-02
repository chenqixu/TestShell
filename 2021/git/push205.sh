#!/usr/bin/expect
cd /bi/user/cqx/data/git/205/
spawn git push
expect "Username"
send "chenqx\n"
expect "Password"
send "Cqx123456\n"
expect eof