#!/usr/bin/env bash
ps -ef|grep `cat /home/redis/redis408/run/redis-10000.pid`|grep -v grep
ps -ef|grep `cat /home/redis/redis408/run/redis-10001.pid`|grep -v grep
ps -ef|grep `cat /home/redis/redis408/run/redis-30000.pid`|grep -v grep
ps -ef|grep `cat /home/redis/redis408/run/redis-30001.pid`|grep -v grep