#!/bin/bash

# 参数：运行轮次 times
times=$1

output_file="/home/ubuntu/result2.csv"

# 固定 d 值列表
d_list=(0 1 2 8 12 15 25 35 50 70 85 100 125 150 175 200 250 300 400 500 600 700 900 1000 1300 1700 2000 2500 5000 9000 20000)

# 构建表头
header="round"
for d in "${d_list[@]}"; do
  header+=",chaseNS_d${d},Mibps_d${d}"
done
echo "$header" > "$output_file"

# 主逻辑放入子 shell 中并后台运行
(
  for (( t=1; t<=times; t++ )); do
    line="$t"
    for d in "${d_list[@]}"; do
      result=$(./multiload -m 768m -s 4096 -l stream-triad-nontemporal-injection-delay -c chaseload -d "$d" -t 32 | grep -Eo '[0-9]+\.[0-9]+' | head -n 2)

      chaseNS=$(echo "$result" | sed -n '1p')
      mibps=$(echo "$result" | sed -n '2p')

      line+=",$chaseNS,$mibps"
    done
    echo "$line" >> "$output_file"
  done

  echo "所有 $times 轮次测试完成，结果已写入：$output_file"
) & disown
