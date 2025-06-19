#!/bin/bash

# measure_throughput.sh - 测量不同缓冲区大小下的I/O吞吐率
#
# 用法:
# 1. 给予执行权限: chmod +x measure_throughput.sh
# 2. 运行并重定向输出到文件: ./measure_throughput.sh > throughput_data.csv
#
# 脚本会将运行进度打印到屏幕(stderr)，并将最终的CSV数据输出到文件(stdout)。

# >&2 表示重定向到标准错误流
echo "Starting throughput measurement..." >&2
echo "Progress will be shown here. CSV output is being sent to stdout." >&2
echo "--------------------------------------------------------------------------------" >&2

# 基础块大小 (我们假设为 4096 字节, 4KB)
BASE_BUF_SIZE=4096

# 总共要传输的数据量 (4GB)
TOTAL_SIZE=$((4 * 1024 * 1024 * 1024))

# 要测试的倍率数组
MULTIPLIERS=(1 2 4 8 16 32 64 128 256 512 1024 2048)

# 首先，输出CSV文件的表头到标准输出
echo "BufferSize(KB),Throughput(GB/s)"

# 循环测试每个倍率
for A in "${MULTIPLIERS[@]}"; do
    # 计算当前的缓冲区大小 (bs)
    CURRENT_BS=$((A * BASE_BUF_SIZE))
    
    # 计算dd命令的count参数
    COUNT=$((TOTAL_SIZE / CURRENT_BS))

    # 将进度信息打印到标准错误
    echo "Testing Multiplier: ${A}x, Buffer Size: $((${CURRENT_BS}/1024)) KB..." >&2

    # 执行dd命令，并将stderr重定向到stdout，以便用grep过滤
    # 2>&1 将 stderr 合并到 stdout
    RESULT=$(dd if=/dev/zero of=/dev/null bs=${CURRENT_BS} count=${COUNT} 2>&1 | grep 'bytes')
    
    # 解析速率和单位 (这一部分逻辑保持不变)
    # 有些系统输出是 "... 14.1 GB/s"，有些是 "... 5,7 GB/s"，用tr处理逗号
    SPEED=$(echo "$RESULT" | tr ',' '.' | awk '{print $(NF-1)}')
    UNIT=$(echo "$RESULT" | awk '{print $NF}')

    # 将所有单位统一转换为 GB/s
    SPEED_GBPS=0
    if [[ "$UNIT" == "GB/s" ]]; then
        SPEED_GBPS=$SPEED
    elif [[ "$UNIT" == "MB/s" ]]; then
        SPEED_GBPS=$(echo "scale=3; $SPEED / 1024" | bc)
    elif [[ "$UNIT" == "kB/s" ]]; then
        SPEED_GBPS=$(echo "scale=6; $SPEED / 1024 / 1024" | bc)
    fi
    
    BUFFER_KB=$((${CURRENT_BS}/1024))
    
    # 将格式化后的CSV数据行输出到标准输出
    echo "${BUFFER_KB},${SPEED_GBPS}"
done

echo "--------------------------------------------------------------------------------" >&2
echo "Measurement complete." >&2