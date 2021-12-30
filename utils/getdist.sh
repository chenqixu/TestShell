#!/usr/bin/env bash
######################################################################
##jstorm集群磁盘巡检
##
######################################################################
#是为了处理df在redhat 6的一个bug
#-x fuse.gvfs-fuse-daemon
ssh 10.48.134.118 "df -hP -x fuse.gvfs-fuse-daemon|grep -E 'home|Filesystem'|awk '{print vhost,\$0}' vhost=\`hostname -i\`;"
for i in 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135; do
  ssh 10.48.134.${i} "df -hP -x fuse.gvfs-fuse-daemon|grep -E 'home'|awk '{print vhost,\$0}' vhost=\`hostname -i\`;"
done
for i in 119 120 121 122 123 124; do
  ssh 10.45.179.${i} "df -hP -x fuse.gvfs-fuse-daemon|grep -E 'home'|awk '{print vhost,\$0}' vhost=\`hostname -i\`;"
done