#!/usr/bin/env bash

#路径
FWDIR="$(cd `dirname $0`;pwd)"
#判断系统是windows还是Linux
system_name=`uname`
if [[ ${system_name} =~ "MINGW64_NT" ]]; then
  FILEPATH="${FWDIR}/../data/"
else
  FILEPATH="${FWDIR}/data/"
fi

echo ${FILEPATH}
FILENAME="1.csv"

#while IFS= read -r line; do
#    str=$(echo "$line" | awk -F '\t' '{print $14}')
#    s1=${line}
##    echo ${s1}
#
#    # 保存当前 IFS
#    OLD_IFS="$IFS"
#
#    # 设置IFS为逗号，分割字符串到数组
#    IFS=',' read -ra arr <<< "$str"
#    if [[ ${#arr[@]} -eq 0 ]]; then
#        echo "${line}"
#    fi
#
#    # 立即恢复 IFS
#    IFS="$OLD_IFS"
#
#    # 循环数组！！！这里有大坑，s1会丢
#    for item in "${arr[@]}"; do
##        echo "${s1}\t${item}"
#        printf "%s\t%s\n" "$s1" "$item"
#    done
#
#done < ${FILEPATH}${FILENAME}

file="${FILEPATH}${FILENAME}"
output_file="${FILEPATH}output.txt"

# 使用 awk 一次性处理，避免所有 shell 循环问题
awk -F '\t' '{
    if (NF >= 14) {
        n = split($14, arr, ",")
        if (n > 0) {
            for (i = 1; i <= n; i++) {
                print $0 "\t" arr[i]
            }
            next
        }
    }
    print $0
}' "$file" > "$output_file"