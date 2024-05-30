#!/bin/bash

WORKLOADS=("Branch" "Imm" "Jump" "Ls" "reg") # workload names


for workload in "${WORKLOADS[@]}"; do
    echo "workload: $workload"
    
    if [ ! -z "$(ls -A simulator )"  ]; then
        echo "try clean file ......................";
        rm simulator/*

    fi

    cp test.v simulator/test_filled_$workload.v
    sed -i 's/WORKLOADARGS/'$workload'/g' simulator/test_filled_$workload.v
    chmod +x simulator/test_filled_$workload.v
    

    iverilog -Wall -pARRAY_SIZE_LIMIT=368435456  -o simulator/sim_$workload  \
    core.v decode.v execute.v fetch.v storagemgmt.v writeBack.v \
    simulator/test_filled_$workload.v

    echo "running workload $workload........."
    vvp simulator/sim_$workload
    echo "finish workload $workload............................................"



done