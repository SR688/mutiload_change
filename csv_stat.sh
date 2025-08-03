#!/bin/bash

# 用法： ./csv_stat.sh input.csv /path/to/output_dir/
input_csv="$1"
output_dir="$2"
output_csv="${output_dir}/output_with_stats.csv"
split_csv="${output_dir}/even_odd_merged.csv"

# 检查输入文件
if [[ ! -f "$input_csv" ]]; then
  echo "输入文件不存在：$input_csv"
  exit 1
fi

# 创建输出目录
mkdir -p "$output_dir"

# 处理并生成含有统计数据的主表
awk -F',' '
NR==1 {
  col_count = NF
  for (i=1; i<=col_count; i++) {
    header[i] = $i
  }
  print $0
  next
}

{
  for (i=1; i<=NF; i++) {
    data[NR-1,i] = $i
    if (i >= 2) {
      sum[i] += $i
      sumsq[i] += ($i)*($i)
      count[i]++
    }
  }
  row_count = NR-1
}

END {
  # 打印原始数据
  for (r=1; r<=row_count; r++) {
    line = data[r,1]
    for (c=2; c<=col_count; c++) {
      line = line "," data[r,c]
    }
    print line
  }

  # 平均值
  line = "AVG"
  for (c=2; c<=col_count; c++) {
    avg = sum[c] / count[c]
    line = line "," sprintf("%.2f", avg)
  }
  print line

  # 总体方差
  line = "VAR"
  for (c=2; c<=col_count; c++) {
    mean = sum[c] / count[c]
    variance = (sumsq[c] - count[c]*mean*mean) / count[c]
    line = line "," sprintf("%.2f", variance)
  }
  print line
}
' "$input_csv" > "$output_csv"

# 合并输出偶数列 + 奇数列
{
  echo "chaseNS"
  awk -F',' '
  {
    line=""
    for (i=2; i<=NF; i+=2) {
      line = (line == "") ? $i : line "," $i
    }
    print line
  }
  ' "$output_csv"

  echo ""
  echo "Mibps"
  awk -F',' '
  {
    line=""
    for (i=3; i<=NF; i+=2) {
      line = (line == "") ? $i : line "," $i
    }
    print line
  }
  ' "$output_csv"
} > "$split_csv"

echo "输出完成："
echo " - 主表格：$output_csv"
echo " - 偶数列与奇数列合并输出：$split_csv"
