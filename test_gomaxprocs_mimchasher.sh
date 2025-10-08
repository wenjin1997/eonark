#!/bin/bash

# 测试不同GOMAXPROCS设置和编译标签下的性能
# 作者: AI Assistant
# 用途: 测试mimchasherinner在不同CPU核心数和编译标签下的性能表现

echo "开始测试不同GOMAXPROCS设置和编译标签下的性能..."
echo "测试时间: $(date)"
echo "=========================================="

# 创建日志目录
LOG_DIR="performance_test_logs_mimchasher"
mkdir -p "$LOG_DIR"

# 测试的GOMAXPROCS值
GOMAXPROCS_VALUES=(1 2 4 8 16 32 64 128 256)

# 测试的编译标签
BUILD_TAGS=("" "purego")

# 遍历不同的编译标签
for tag in "${BUILD_TAGS[@]}"; do
    # 设置标签名称用于日志文件
    if [ -z "$tag" ]; then
        TAG_NAME="default"
        TAG_FLAG=""
    else
        TAG_NAME="$tag"
        TAG_FLAG="-tags $tag"
    fi
    
    echo ""
    echo "=========================================="
    echo "测试编译标签: $TAG_NAME"
    echo "=========================================="
    
    # 遍历不同的GOMAXPROCS值
    for procs in "${GOMAXPROCS_VALUES[@]}"; do
        echo "正在测试 GOMAXPROCS=$procs, TAG=$TAG_NAME..."
        
        # 设置日志文件名
        LOG_FILE="$LOG_DIR/gomaxprocs_${procs}_${TAG_NAME}_$(date +%Y%m%d_%H%M%S).log"
        
        # 运行程序并保存输出到日志文件
        {
            echo "=========================================="
            echo "测试 GOMAXPROCS=$procs, TAG=$TAG_NAME"
            echo "开始时间: $(date)"
            echo "=========================================="
            
            # 运行程序，设置GOMAXPROCS环境变量和编译标签
            if [ -z "$TAG_FLAG" ]; then
                GOMAXPROCS=$procs go run examples/mimchasher/main.go
            else
                GOMAXPROCS=$procs go run $TAG_FLAG examples/mimchasher/main.go
            fi
            
            echo ""
            echo "结束时间: $(date)"
            echo "----------------------------------------"
        } 2>&1 | tee "$LOG_FILE"
        
        # 检查程序是否成功运行
        if [ $? -eq 0 ]; then
            echo "GOMAXPROCS=$procs, TAG=$TAG_NAME 测试完成 ✅"
            echo "日志保存到: $LOG_FILE"
        else
            echo "GOMAXPROCS=$procs, TAG=$TAG_NAME 测试失败 ❌"
            echo "错误日志保存到: $LOG_FILE"
        fi
        
        # 等待一秒再进行下一个测试
        sleep 1
    done
done

echo ""
echo "=========================================="
echo "所有测试完成!"
echo "日志文件保存在: $LOG_DIR/"
echo "=========================================="

# 显示日志文件列表
echo "生成的日志文件:"
ls -la "$LOG_DIR/"
