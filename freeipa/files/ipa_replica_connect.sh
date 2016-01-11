#!/bin/bash -x
# Look for list of my connected nodes, compare it to list of all nodes and
# connect missing ones

# my nodes
declare -a SEEN
let count=0

IN=$(echo "$(TERM= ipa-replica-manage list $(grep host /etc/ipa/default.conf | cut -d'=' -f2) || echo "x" )" | cut -d':' -f1 )
[ $IN == 'x' ] && exit 1

ND=$(echo "$(TERM= ipa-replica-manage list || echo "x" )" | grep -v $(grep host /etc/ipa/default.conf | cut -d'=' -f2) | cut -d':' -f1 )
[ $ND == 'x' ] && exit 1

for LINE in ${IN}; do
    SEEN[$count]=${LINE}
    ((count++))
done

# what I can see
declare -a NODES
let count=0
for LINE in ${ND}; do
    let conn=0
    for ((i=0;i<${#SEEN[@]};i++)); do
        [ "x${LINE}" == "x${SEEN[${i}]}" ] && conn=1
    done
    if [ $conn -eq 0 ]; then
        NODES[$count]=$LINE
        ((count++))
    fi
done

# connect new replicas
for ((j=0;j<${#NODES[@]};j++)); do
    ipa-replica-manage connect ${NODES[${j}]} || exit 1
done
