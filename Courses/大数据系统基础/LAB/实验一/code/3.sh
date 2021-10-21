#!/bin/bash --login
echo 'mkdir -p ~/multi-nodes' > agent.sh             # 在节点主目录下创建multi-nodes目录

# 让每个节点运行任务，将结果保存在各自的~/multi-nodes/result文件中
echo "grep '^t' ~/multi-nodes/part > ~/multi-nodes/result" >> agent.sh

# 将所有节点的计算结果传至thumm01(当前操作的主机)
echo "scp ~/multi-nodes/result thumm01:~/multi-nodes/" >> agent.sh

mkdir -p ~/multi-nodes
cd multi-nodes

for ((i=1;i<6;i=i+1));do
    mkdir -p thumm0$(($i+1))
done
wait

lines=`cat ../wc_bigdataset.txt | wc -l`     # 计算wc_bigdataset.txt的行数
lines_per_node=$(($lines/5+1))              # 将wc_bigdataset.txt分为5部分，计算每部的行数
split -l $lines_per_node ../wc_bigdataset.txt -d part  # 划分wc_dataset.txt为part00-part05

# 将不同的部分分别传至不同的节点
for ((i=0;i<5;i=i+1));do
    scp part0$i thumm0$(($i+2)):~/multi-nodes/part &
done
wait  # 等待节点传输完成
for ((i=1;i<6;i=i+1));do
    ssh thumm0$(($i+1)) < ~/agent.sh &
done
wait

for ((i=1;i<6;i=i+1));do
    scp thumm0$(($i+1)):~/multi-nodes/result ~/multi-nodes/thumm0$(($i+1))/ &
done
wait

# 将所有结果整合成一个文件：t_head_multi_node.txt
rm -rf ~/multi-nodes/t_head_multi_node.txt
for ((i=2; i<=6; i=i+1)); do
    cat ~/multi-nodes/thumm0$i/result >> ~/multi-nodes/t_head_multi_node.txt
done
