#!/bin/bash

# 增强版性能对比分析脚本
# 支持多种输出格式：终端显示、文本文件、CSV文件

# 设置输出文件
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEXT_OUTPUT="performance_analysis_${TIMESTAMP}.txt"
CSV_OUTPUT="performance_analysis_${TIMESTAMP}.csv"

echo "=========================================="
echo "GOMAXPROCS + 编译标签 性能对比分析 (增强版)"
echo "=========================================="
echo "分析结果将保存到:"
echo "  - 文本格式: $TEXT_OUTPUT"
echo "  - CSV格式: $CSV_OUTPUT"
echo ""

# 创建CSV文件头部
echo "GOMAXPROCS,Build_Tag,Compile_ms,Prove_ms,Verify_ms,Prover_ms" > "$CSV_OUTPUT"

# 将所有输出重定向到文件，同时在终端显示
exec > >(tee "$TEXT_OUTPUT") 2>&1

LOG_DIR="performance_test_logs"

# 检查日志目录是否存在
if [ ! -d "$LOG_DIR" ]; then
    echo "错误: 日志目录 $LOG_DIR 不存在"
    exit 1
fi

echo "分析日志文件..."
echo ""

# 创建性能对比表格 - 按编译标签分组
echo "=========================================="
echo "按编译标签分组的性能对比"
echo "=========================================="

# 分析默认编译标签
echo ""
echo "--- 默认编译标签 (无 -tags purego) ---"
printf "%-12s %-15s %-15s %-15s %-15s\n" "GOMAXPROCS" "Compile(ms)" "Prove(ms)" "Verify(ms)" "Prover(ms)"
echo "----------------------------------------------------------------"

for log_file in "$LOG_DIR"/gomaxprocs_*_default_*.log; do
    if [ -f "$log_file" ]; then
        # 提取GOMAXPROCS值
        procs=$(basename "$log_file" | grep -o 'gomaxprocs_[0-9]\+' | grep -o '[0-9]\+')
        
        # 提取关键性能指标
        compile_time=$(grep "compile inner 耗时" "$log_file" | grep -o '[0-9.]\+[ms]' | head -1 | sed 's/ms//')
        prove_time=$(grep "prove inner 耗时" "$log_file" | grep -o '[0-9.]\+[ms]' | head -1 | sed 's/ms//')
        verify_time=$(grep "verify inner 耗时" "$log_file" | grep -o '[0-9.]\+[ms]' | head -1 | sed 's/ms//')
        prover_time=$(grep "prover 总耗时" "$log_file" | grep -o '[0-9.]\+[ms]' | head -1 | sed 's/ms//')
        
        # 转换时间单位 (s -> ms)
        if [[ "$compile_time" == *"s" ]]; then
            compile_ms=$(echo "$compile_time" | sed 's/s//' | awk '{print $1 * 1000}')
        else
            compile_ms="$compile_time"
        fi
        
        if [[ "$prove_time" == *"s" ]]; then
            prove_ms=$(echo "$prove_time" | sed 's/s//' | awk '{print $1 * 1000}')
        else
            prove_ms="$prove_time"
        fi
        
        printf "%-12s %-15s %-15s %-15s %-15s\n" "$procs" "$compile_ms" "$prove_ms" "$verify_time" "$prover_time"
        
        # 写入CSV文件
        echo "$procs,default,$compile_ms,$prove_ms,$verify_time,$prover_time" >> "$CSV_OUTPUT"
    fi
done

# 分析purego编译标签
echo ""
echo "--- PureGo编译标签 (-tags purego) ---"
printf "%-12s %-15s %-15s %-15s %-15s\n" "GOMAXPROCS" "Compile(ms)" "Prove(ms)" "Verify(ms)" "Prover(ms)"
echo "----------------------------------------------------------------"

for log_file in "$LOG_DIR"/gomaxprocs_*_purego_*.log; do
    if [ -f "$log_file" ]; then
        # 提取GOMAXPROCS值
        procs=$(basename "$log_file" | grep -o 'gomaxprocs_[0-9]\+' | grep -o '[0-9]\+')
        
        # 提取关键性能指标
        compile_time=$(grep "compile inner 耗时" "$log_file" | grep -o '[0-9.]\+[ms]' | head -1 | sed 's/ms//')
        prove_time=$(grep "prove inner 耗时" "$log_file" | grep -o '[0-9.]\+[ms]' | head -1 | sed 's/ms//')
        verify_time=$(grep "verify inner 耗时" "$log_file" | grep -o '[0-9.]\+[ms]' | head -1 | sed 's/ms//')
        prover_time=$(grep "prover 总耗时" "$log_file" | grep -o '[0-9.]\+[ms]' | head -1 | sed 's/ms//')
        
        # 转换时间单位 (s -> ms)
        if [[ "$compile_time" == *"s" ]]; then
            compile_ms=$(echo "$compile_time" | sed 's/s//' | awk '{print $1 * 1000}')
        else
            compile_ms="$compile_time"
        fi
        
        if [[ "$prove_time" == *"s" ]]; then
            prove_ms=$(echo "$prove_time" | sed 's/s//' | awk '{print $1 * 1000}')
        else
            prove_ms="$prove_time"
        fi
        
        printf "%-12s %-15s %-15s %-15s %-15s\n" "$procs" "$compile_ms" "$prove_ms" "$verify_time" "$prover_time"
        
        # 写入CSV文件
        echo "$procs,purego,$compile_ms,$prove_ms,$verify_time,$prover_time" >> "$CSV_OUTPUT"
    fi
done

echo ""
echo "=========================================="
echo "编译标签性能对比总结"
echo "=========================================="

# 计算性能差异
echo ""
echo "性能差异分析 (PureGo vs 默认):"
echo ""

# 这里可以添加更详细的对比分析逻辑
echo "1. 默认编译: 使用平台特定的汇编优化"
echo "2. PureGo编译: 使用纯Go实现，无汇编优化"
echo "3. 预期PureGo版本会较慢，但具有更好的可移植性"
echo ""

echo "=========================================="
echo "详细组件性能分析"
echo "=========================================="

# 分析每个组件的性能 - 按编译标签分组
components=("initBlindingPolynomials" "solveConstraints" "deriveGammaAndBeta" "buildRatioCopyConstraint" "computeQuotient" "openZ" "computeLinearizedPolynomial" "batchOpening")

for component in "${components[@]}"; do
    echo ""
    echo "--- $component ---"
    printf "%-12s %-15s %-15s %-15s\n" "GOMAXPROCS" "Default(ms)" "PureGo(ms)" "差异(%)"
    echo "------------------------------------------------"
    
    # 获取所有GOMAXPROCS值
    for procs in 1 2 4 8; do
        default_file=$(ls "$LOG_DIR"/gomaxprocs_${procs}_default_*.log 2>/dev/null | head -1)
        purego_file=$(ls "$LOG_DIR"/gomaxprocs_${procs}_purego_*.log 2>/dev/null | head -1)
        
        if [ -f "$default_file" ] && [ -f "$purego_file" ]; then
            default_time=$(grep "${component} 耗时" "$default_file" | grep -o '[0-9.]\+[µms]' | head -1 | sed 's/[µms]//')
            purego_time=$(grep "${component} 耗时" "$purego_file" | grep -o '[0-9.]\+[µms]' | head -1 | sed 's/[µms]//')
            
            # 转换微秒到毫秒
            if [[ "$default_time" == *"µ" ]]; then
                default_ms=$(echo "$default_time" | sed 's/µ//' | awk '{print $1 / 1000}')
            else
                default_ms="$default_time"
            fi
            
            if [[ "$purego_time" == *"µ" ]]; then
                purego_ms=$(echo "$purego_time" | sed 's/µ//' | awk '{print $1 / 1000}')
            else
                purego_ms="$purego_time"
            fi
            
            # 计算差异百分比
            if [ -n "$default_ms" ] && [ -n "$purego_ms" ] && [ "$default_ms" != "0" ]; then
                diff_percent=$(echo "scale=1; ($purego_ms - $default_ms) / $default_ms * 100" | bc 2>/dev/null || echo "N/A")
            else
                diff_percent="N/A"
            fi
            
            printf "%-12s %-15s %-15s %-15s\n" "$procs" "$default_ms" "$purego_ms" "$diff_percent"
        fi
    done
done

echo ""
echo "=========================================="
echo "性能总结"
echo "=========================================="
echo "1. 测试环境说明:"
echo "   - mimchasherinner: 仅使用环境变量GOMAXPROCS控制并发"
echo "   - mimchasher: 使用runtime.LockOSThread()固定为单个OS线程"
echo "2. 测试维度:"
echo "   - GOMAXPROCS: 1, 2, 4, 8"
echo "   - 编译标签: 默认 vs PureGo"
echo "3. 性能差异主要来自:"
echo "   - Go运行时调度器的开销"
echo "   - 内存分配和垃圾回收的影响"
echo "   - 编译器优化程度"
echo "   - 汇编优化 vs 纯Go实现的差异"
echo "4. 建议:"
echo "   - 使用GOMAXPROCS=1进行CPU密集型单线程性能测试"
echo "   - 默认编译用于性能优化"
echo "   - PureGo编译用于可移植性"
echo "=========================================="
echo ""
echo "分析完成！结果已保存到:"
echo "  - 文本格式: $TEXT_OUTPUT"
echo "  - CSV格式: $CSV_OUTPUT"
echo "生成时间: $(date)"
