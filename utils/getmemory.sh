#!/usr/bin/env bash
######################################################################
##jstorm集群内存巡检
##
######################################################################
ssh 10.48.134.118 "free -g|head -n2|grep -E 'total|Mem'|awk '{print vhost,\$0}' vhost=\`hostname -i\`;"
for i in 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135; do
  ssh 10.48.134.${i} "free -g|head -n2|grep -E 'Mem'|awk '{print vhost,\$0}' vhost=\`hostname -i\`;"
done
for i in 119 120 121 122 123 124; do
  ssh 10.45.179.${i} "free -g|head -n2|grep -E 'Mem'|awk '{print vhost,\$0}' vhost=\`hostname -i\`;"
done