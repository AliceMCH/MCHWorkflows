set term png small size 800,600
set output "mem-graph.png"

set ylabel "%MEM task"

set ytics nomirror

#set yrange [3900000:4100000]

plot "/tmp/mem.log" using 3 with lines axes x1y1 title "%MEM task"
