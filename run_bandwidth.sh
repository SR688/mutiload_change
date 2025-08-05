#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <times>"
  exit 1
fi
times=$1
outfile="results.csv"
echo "round,Full-read-bandwidth,Read-write-1-1-bandwidth,stream-triad-nontemporal-injection-delay,Read-write-2-1-bandwidth,Read-write-3-1-bandwidth" > "$outfile"

trap 'echo "Interrupted by user." >&2; exit 1' INT

progress_file="progress.$$"
echo "0" > "$progress_file"

for ((i=1;i<=times;i++)); do
  echo "$i" > "$progress_file"
  echo "Round $i: starting measurement..." >&2

  cmd1=$(./multiload -t 32 -m 768M -l Full-read-bandwidth -H -s 4096 -n 15 | awk '{print $NF}')
  cmd2=$(./multiload -t 32 -m 768M -l Read-write-1-1-bandwidth -H -s 4096 -n 15 | awk '{print $NF}')
  cmd3=$(./multiload -t 32 -m 768M -l stream-triad-nontemporal-injection-delay -H -s 4096 -n 15 | awk '{print $NF}')
  cmd4=$(./multiload -t 32 -m 768M -l Read-write-2-1-bandwidth -H -s 4096 -n 15 | awk '{print $NF}')
  cmd5=$(./multiload -t 32 -m 768M -l Read-write-3-1-bandwidth -H -s 4096 -n 15 | awk '{print $NF}')

  fmt(){ printf "%.2f" "$(echo "$1 * 1.048576" | bc -l)"; }
  v1=$(fmt "$cmd1")
  v2=$(fmt "$cmd2")
  v3=$(fmt "$cmd3")
  v4=$(fmt "$cmd4")
  v5=$(fmt "$cmd5")

  echo "$i,$v1,$v2,$v3,$v4,$v5" >> "$outfile"
done

rm -f "$progress_file"

# 添加一行平均值，然后一行标准差
awk -F, '
NR==1 {
  header = $0
  next
}
{
  rows++
  for (j=2; j<=NF; j++) {
    sum[j] += $j
    sum2[j] += ($j)^2
  }
}
END {
  printf("%s\n", header)
  # 平均值行
  printf("average")
  for (j=2; j<=NF; j++) {
    avg = sum[j] / rows
    printf(",%.2f", avg)
  }
  printf("\n")
  # 标准差（population）
  printf("stddev")
  for (j=2; j<=NF; j++) {
    avg = sum[j] / rows
    std = sqrt(sum2[j]/rows - avg^2)
    printf(",%.2f", std)
  }
  printf("\n")
}' "$outfile" >> "${outfile}.tmp"

# 覆盖原文件
mv "${outfile}.tmp" "$outfile"

echo "Done. Outputs in $outfile"
