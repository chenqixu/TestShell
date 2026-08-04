#!/bin/bash
###############################################################################
# check_vmstat_swap.sh
# 功能：解析 vmstat 日志，判断 si/so 是否存在较高的情况
# 用法：./check_vmstat_swap.sh <日志文件> [si阈值] [so阈值]
# 示例：./check_vmstat_swap.sh /var/log/vmstat_monitor/vmstat_20260804.log 100 50
###############################################################################

######################################################################
##参数设置
######################################################################
##判断系统是windows还是Linux
system_name=`uname`
##路径
FWDIR="$(cd `dirname $0`;pwd)"
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]路径=${FWDIR}"

LOG_FILE="${FWDIR}/log/vmstat_monitor/vmstat_$(date +%Y%m%d).log"
SI_THRESHOLD="${2:-100}"   # si 阈值（KB/s），默认 100
SO_THRESHOLD="${3:-50}"    # so 阈值（KB/s），默认 50

# 颜色定义
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
CYAN='\033[36m'
NC='\033[0m'

# 检查文件是否存在
if [ ! -f "$LOG_FILE" ]; then
    echo -e "${RED}[ERROR] 日志文件不存在: $LOG_FILE${NC}"
    echo "用法: $0 <日志文件> [si阈值] [so阈值]"
    exit 1
fi

echo "============================================================"
echo -e "${CYAN}  vmstat Swap 抖动检测报告${NC}"
echo "============================================================"
echo "日志文件    : $LOG_FILE"
echo "检测时间    : $(date '+%Y-%m-%d %H:%M:%S')"
echo "SI 阈值     : ${SI_THRESHOLD} KB/s"
echo "SO 阈值     : ${SO_THRESHOLD} KB/s"
echo "============================================================"
echo ""

# 状态统计
total_lines=0
si_alert_count=0
so_alert_count=0
both_alert_count=0
max_si=0
max_so=0
max_si_time=""
max_so_time=""
current_snapshot=""
snapshot_si_max=0
snapshot_so_max=0

# 逐行解析
while IFS= read -r line; do
    # 捕获快照时间戳
    if [[ "$line" =~ \[([0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2})\].*Start\ vmstat ]]; then
        # 输出上一个快照的汇总
        if [ -n "$current_snapshot" ]; then
            echo ""
            if [ "$snapshot_si_max" -gt "$SI_THRESHOLD" ] || [ "$snapshot_so_max" -gt "$SO_THRESHOLD" ]; then
                echo -e "  ${RED}>>> 本快照存在 Swap 抖动!${NC}  SI峰值=${snapshot_si_max}  SO峰值=${snapshot_so_max}"
            else
                echo -e "  ${GREEN}>>> 本快照正常${NC}  SI峰值=${snapshot_si_max}  SO峰值=${snapshot_so_max}"
            fi
        fi
        current_snapshot="${BASH_REMATCH[1]}"
        snapshot_si_max=0
        snapshot_so_max=0
        echo "------------------------------------------------------------"
        echo -e "${CYAN}快照时间: $current_snapshot${NC}"
        echo "  SI    SO   状态"
        echo "------ ------ ----------"
        continue
    fi

    # 跳过表头行
    if [[ "$line" =~ ^procs ]] || [[ "$line" =~ ^\ r ]] || [[ "$line" =~ ^swpd ]]; then
        continue
    fi

    # 跳过空行或分隔行
    if [[ -z "$line" ]] || [[ "$line" =~ ^\[ ]]; then
        continue
    fi

    # 解析数据行：提取 si(第7列) 和 so(第8列)
    # vmstat 输出列: r b swpd free buff cache si so bi bo in cs us sy id wa st
    read -r r b swpd free buff cache si so bi bo in cs us sy id wa st <<< "$line"

    # 验证是否为纯数字行
    if ! [[ "$si" =~ ^[0-9]+$ ]] || ! [[ "$so" =~ ^[0-9]+$ ]]; then
        continue
    fi

    total_lines=$((total_lines + 1))

    # 更新全局最大值
    if [ "$si" -gt "$max_si" ]; then
        max_si="$si"
        max_si_time="$current_snapshot"
    fi
    if [ "$so" -gt "$max_so" ]; then
        max_so="$so"
        max_so_time="$current_snapshot"
    fi

    # 更新快照内最大值
    if [ "$si" -gt "$snapshot_si_max" ]; then
        snapshot_si_max="$si"
    fi
    if [ "$so" -gt "$snapshot_so_max" ]; then
        snapshot_so_max="$so"
    fi

    # 判断告警
    si_flag=""
    so_flag=""
    if [ "$si" -gt "$SI_THRESHOLD" ]; then
        si_alert_count=$((si_alert_count + 1))
        si_flag="${RED}⚠ SI超高${NC}"
    fi
    if [ "$so" -gt "$SO_THRESHOLD" ]; then
        so_alert_count=$((so_alert_count + 1))
        so_flag="${YELLOW}⚠ SO超高${NC}"
    fi

    # 打印当前行
    if [ -n "$si_flag" ] || [ -n "$so_flag" ]; then
        printf "  ${RED}%-5s${NC} ${RED}%-5s${NC} ${si_flag} ${so_flag}\n" "$si" "$so"
        if [ "$si" -gt "$SO_THRESHOLD" ] 2>/dev/null && [ "$so" -gt "$SO_THRESHOLD" ] 2>/dev/null; then
            both_alert_count=$((both_alert_count + 1))
        fi
    else
        printf "  %-5s  %-5s  ${GREEN}正常${NC}\n" "$si" "$so"
    fi

done < "$LOG_FILE"

# 输出最后一个快照的汇总
if [ -n "$current_snapshot" ]; then
    echo ""
    if [ "$snapshot_si_max" -gt "$SI_THRESHOLD" ] || [ "$snapshot_so_max" -gt "$SO_THRESHOLD" ]; then
        echo -e "  ${RED}>>> 本快照存在 Swap 抖动!${NC}  SI峰值=${snapshot_si_max}  SO峰值=${snapshot_so_max}"
    else
        echo -e "  ${GREEN}>>> 本快照正常${NC}  SI峰值=${snapshot_si_max}  SO峰值=${snapshot_so_max}"
    fi
fi

# ===================== 汇总报告 =====================
echo ""
echo "============================================================"
echo -e "${CYAN}  汇总报告${NC}"
echo "============================================================"
echo "总采样行数       : $total_lines"
echo "SI 超阈值次数    : ${si_alert_count} 次  (阈值: ${SI_THRESHOLD} KB/s)"
echo "SO 超阈值次数    : ${so_alert_count} 次  (阈值: ${SO_THRESHOLD} KB/s)"
echo "SI 全局峰值      : ${max_si} KB/s  (时间: ${max_si_time:-N/A})"
echo "SO 全局峰值      : ${max_so} KB/s  (时间: ${max_so_time:-N/A})"
echo "------------------------------------------------------------"

# 最终判定
if [ "$si_alert_count" -eq 0 ] && [ "$so_alert_count" -eq 0 ]; then
    echo -e "${GREEN}✅ 判定结果: 未发现 Swap 抖动，系统 Swap 活动正常${NC}"
    echo -e "   说明: si/so 全程为 0 或极低，Swap 只是静态占用，不影响性能"
    echo -e "   建议: 50% 告警大概率是误报，建议调整告警策略为组合指标"
    exit 0
elif [ "$si_alert_count" -gt 0 ] && [ "$so_alert_count" -gt 0 ]; then
    echo -e "${RED}�判定结果: 存在明显的 Swap 抖动！${NC}"
    echo -e "   SI 超阈值 ${si_alert_count} 次, SO 超阈值 ${so_alert_count} 次"
    echo -e "   建议: 立即排查内存不足问题，检查 Java 堆配置 (-Xmx)"
    echo -e "   建议: 执行 sysctl vm.swappiness=1 临时缓解"
    exit 2
elif [ "$si_alert_count" -gt 0 ]; then
    echo -e "${YELLOW}�判定结果: 存在 Swap 换入活动 (si > 0)${NC}"
    echo -e "   SI 超阈值 ${si_alert_count} 次"
    echo -e "   建议: 关注内存压力，检查是否有进程内存泄漏"
    exit 1
else
    echo -e "${YELLOW}�判定结果: 存在 Swap 换出活动 (so > 0)${NC}"
    echo -e "   SO 超阈值 ${so_alert_count} 次"
    echo -e "   建议: 系统正在把内存换到磁盘，关注可用内存是否充足"
    exit 1
fi