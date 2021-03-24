#!/usr/bin/env bash
kill -9 `cat /home/redis/redis408/run/redis-10000.pid`
kill -9 `cat /home/redis/redis408/run/redis-10001.pid`
kill -9 `cat /home/redis/redis408/run/redis-30000.pid`
kill -9 `cat /home/redis/redis408/run/redis-30001.pid`