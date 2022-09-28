#!/usr/bin/env bash
######################################################################
##检查哪些应用使用了swap空间
##
######################################################################
#!/bin/bash
for pid in `jps|awk '{print $1}'`
do
  if [[ -f "/proc/$pid/status" ]]; then
    echo "$pid "`grep Swap /proc/$pid/status`;
  fi
done