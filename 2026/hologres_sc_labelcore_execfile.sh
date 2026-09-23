#!/usr/bin/env bash
##参数检查
if [[ $# -ne 1 ]]; then
    echo "你需要输入1个参数."
    echo "1] 执行的SQL文件（可以是本目录下的，也可以是完整路径）."
    exit 1
fi
exec_sql_file=$1
# 判断是否是文件
if [[ -f "${exec_sql_file}" ]]; then
    echo "执行sql文件: ${exec_sql_file}"
else
    echo "${exec_sql_file}不是文件"
    exit 1
fi
echo "=====5行文件示例内容展示====="
awk 'NR <= 5 {print "["NR"]: "$0}' "${exec_sql_file}"
echo "====="
read -p "确定要继续吗? [y/N]: " confirm
if [[ "$confirm" = "y" ] || [ "$confirm" = "Y" ]]; then
    echo "继续执行..."
else
    echo "操作已取消"
    exit 1
fi
# 切换用户
sed '1i set search_path to label_core;' "${exec_sql_file}" > tmp.txt
# 执行文件
/bi/sysapp/apsaradb_for_gp_client_package/bin/psql "host=10.44.186.7 port=80 dbname=label_core user=x2Xqg603xaJhJN1a password=hOsIF3cAg28N7ftb8VMNto1xU8JUgd" -f tmp.txt
