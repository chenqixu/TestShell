#!/bin/bash
###############################################################################
# vmstat_logger.sh — 持续采集 vmstat 数据，按天滚动日志
#
# 功能：
#   1. 后台运行，每天自动生成独立日志文件
#   2. 支持 start / stop / restart / status / check 子命令
#   3. 自动清理超过保留天数的旧日志
#   4. 日志带时间戳，格式清晰，可直接被分析脚本消费
#
# 用法：
#   ./vmstat_logger.sh start          # 启动采集
#   ./vmstat_logger.sh stop           # 停止采集
#   ./vmstat_logger.sh restart       # 重启采集
#   ./vmstat_logger.sh status         # 查看运行状态
#   ./vmstat_logger.sh check          # 健康检查 + Swap 抖动检测
#
# 可调参数（脚本顶部修改）：
#   INTERVAL      每轮采集间隔秒数（默认 30）
#   COUNT         每轮采集样本数（默认 5）
#   DELAY         每轮内样本间隔秒数（默认 1，即 vmstat 1 5）
#   LOG_DIR       日志目录
#   RETAIN_DAYS   日志保留天数（默认 30）
#   PID_FILE      PID 文件路径
###############################################################################

######################################################################
##参数设置
######################################################################
##判断系统是windows还是Linux
system_name=`uname`
##路径
FWDIR="$(cd `dirname $0`;pwd)"
# ===================== 可配置参数 =====================
INTERVAL=30         # 每轮采集间隔（秒）
COUNT=5              # 每轮采集样本数
DELAY=1              # 每轮内样本间隔（秒）
LOG_DIR="${FWDIR}/log/vmstat_monitor"
RETAIN_DAYS=30       # 日志保留天数
PID_FILE="${FWDIR}/log/vmstat_logger.pid"
# =====================================================

# 确保日志目录存在
mkdir -p "$LOG_DIR" 2>/dev/null || {
    echo "❌ 无法创建日志目录 $LOG_DIR，请检查权限"
    exit 1
}

# 获取今天的日志文件路径
get_log_file() {
    echo "${LOG_DIR}/vmstat_$(date +%Y%m%d).log"
}

# 日志函数：带时间戳写入
write_log() {
    local msg="$1"
    local log_file
    log_file="$(get_log_file)"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" >> "$log_file"
}

# 清理旧日志
cleanup_old_logs() {
    find "$LOG_DIR" -name "vmstat_*.log" -type f -mtime +${RETAIN_DAYS} -delete 2>/dev/null
}

# 采集一轮 vmstat 数据
collect_once() {
    local log_file
    log_file="$(get_log_file)"

    {
        echo ""
        echo "===== vmstat snapshot @ $(date '+%Y-%m-%d %H:%M:%S') ====="
        vmstat "$DELAY" "$COUNT"
    } >> "$log_file"
}

# 后台主循环（被 nohup 调用时执行此函数）
daemon_main() {
    # 写入启动标记
    write_log "vmstat_logger 启动 (INTERVAL=${INTERVAL}s, COUNT=${COUNT}, DELAY=${DELAY}s)"
    echo $$ > "$PID_FILE"

    # 捕获退出信号，写停止标记
    trap 'write_log "vmstat_logger 停止"; rm -f "$PID_FILE"; exit 0' SIGTERM SIGINT SIGQUIT

    while true; do
        # 日切检测：如果跨天，先清理旧日志
        cleanup_old_logs

        # 执行采集
        collect_once

        # 等待下一轮
        sleep "$INTERVAL"
    done
}

# ===================== 子命令处理 =====================

cmd_start() {
    # 检查是否已在运行
    if [ -f "$PID_FILE" ]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
            echo "vmstat_logger 已在运行 (PID: $old_pid)"
            echo "  日志文件: $(get_log_file)"
            return 0
        else
            # PID 文件存在但进程已死，清理
            rm -f "$PID_FILE"
        fi
    fi

    echo "启动 vmstat_logger ..."
    echo "  采集间隔: ${INTERVAL}s | 每轮样本: ${COUNT} | 样本间隔: ${DELAY}s"
    echo "  日志目录: ${LOG_DIR}"
    echo "  保留天数: ${RETAIN_DAYS} 天"

    # 使用 nohup + setsid 确保脱离终端后台运行
    nohup setsid "$0" __daemon__ >/dev/null 2>&1 &

    # 等待一小会儿确认启动成功
    sleep 2
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "✅ 启动成功 (PID: $pid)"
            echo "  今日日志: $(get_log_file)"
            echo ""
            echo "  查看实时日志: tail -f $(get_log_file)"
            echo "  停止采集:     $0 stop"
        else
            echo "❌ 启动失败，请检查权限和 vmstat 是否可用"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        echo "❌ 启动失败（未生成 PID 文件）"
        return 1
    fi
}

cmd_stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo "vmstat_logger 未运行（无 PID 文件）"
        return 0
    fi

    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)

    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
        echo "vmstat_logger 未运行（PID 文件无效）"
        rm -f "$PID_FILE"
        return 0
    fi

    echo "停止 vmstat_logger (PID: $pid) ..."
    kill -TERM "$pid" 2>/dev/null

    # 等待最多 5 秒确认退出
    local i=0
    while kill -0 "$pid" 2>/dev/null && [ $i -lt 5 ]; do
        sleep 1
        i=$((i + 1))
    done

    if kill -0 "$pid" 2>/dev/null; then
        echo "进程未响应 SIGTERM，发送 SIGKILL"
        kill -KILL "$pid" 2>/dev/null
    fi

    rm -f "$PID_FILE"
    echo "✅ 已停止"
}

cmd_restart() {
    cmd_stop
    sleep 1
    cmd_start
}

cmd_status() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "vmstat_logger 运行中 (PID: $pid)"
            echo "  运行时长: $(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ')"
            echo "  今日日志: $(get_log_file)"
            local logf
            logf="$(get_log_file)"
            if [ -f "$logf" ]; then
                echo "  日志大小: $(du -h "$logf" 2>/dev/null | cut -f1)"
            fi
            echo "  日志总数: $(find "$LOG_DIR" -name 'vmstat_*.log' 2>/dev/null | wc -l) 个文件"
            echo ""
            echo "  最近采集数据："
            echo "  ----------------------------------------"
            tail -7 "$(get_log_file)" 2>/dev/null | sed 's/^/  /'
        else
            echo "vmstat_logger 未运行（PID 文件无效）"
            rm -f "$PID_FILE"
        fi
    else
        echo "vmstat_logger 未运行"
    fi
}

cmd_check() {
    # 检查最近一次采集是否正常（日志是否更新、si/so 是否异常）
    local log_file
    log_file="$(get_log_file)"

    if [ ! -f "$log_file" ]; then
        echo "❌ 今日日志不存在: $log_file"
        return 1
    fi

    local last_modify
    last_modify=$(stat -c %Y "$log_file" 2>/dev/null)
    local now
    now=$(date +%s)
    local age=$((now - last_modify))

    echo "健康检查报告"
    echo "  日志文件: $log_file"
    echo "  最后更新: ${age} 秒前"
    local sz
    sz=$(du -h "$log_file" 2>/dev/null | cut -f1)
    echo "  日志大小: ${sz:-N/A}"

    if [ "$age" -gt $((INTERVAL * 2)) ]; then
        echo "⚠️  日志已超过 2 个采集周期未更新，采集可能已停止！"
    else
        echo "✅ 日志更新正常"
    fi

    # 提取最近一次 vmstat 数据的 si/so 列
    echo ""
    echo "  最近一次快照的 si/so 峰值："
    local si_peak so_peak
    si_peak=$(awk '/^[[:space:]]+[0-9]/{print $7}' "$log_file" | sort -n | tail -1)
    so_peak=$(awk '/^[[:space:]]+[0-9]/{print $8}' "$log_file" | sort -n | tail -1)
    echo "  SI 峰值: ${si_peak:-0} KB/s"
    echo "  SO 峰值: ${so_peak:-0} KB/s"

    if [ "${si_peak:-0}" -gt 100 ] || [ "${so_peak:-0}" -gt 50 ]; then
        echo "⚠️  检测到 Swap 抖动（SI>${si_peak} 或 SO>${so_peak}）"
        return 1
    else
        echo "✅ 未发现 Swap 抖动"
    fi
}

# ===================== 入口 =====================
ACTION="${1:-start}"

# 如果是 __daemon__ 参数，进入后台主循环
if [ "$ACTION" = "__daemon__" ]; then
    daemon_main
    exit 0
fi

case "$ACTION" in
    start)   cmd_start   ;;
    stop)    cmd_stop    ;;
    restart) cmd_restart ;;
    status)  cmd_status  ;;
    check)   cmd_check   ;;
    *)
        echo "用法: $0 {start|stop|restart|status|check}"
        echo ""
        echo "  start    启动后台采集（默认）"
        echo "  stop     停止后台采集"
        echo "  restart  重启采集"
        echo "  status   查看运行状态"
        echo "  check    健康检查 + Swap 抖动检测"
        exit 1
        ;;
esac
