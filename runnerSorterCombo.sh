#!/bin/bash

WORKLOADS=( "sorter" ) # workload names


for workload in "${WORKLOADS[@]}"; do
    echo "workload: $workload"

    ##### clear the directory    
    if [ ! -z "$(ls -A simulator )"  ]; then
        echo "try clean file ......................";
        rm simulator/*

    fi

    ##### augment file
    cp testSorterCombo.v simulator/test_filled_$workload.v
    sed -i 's/WORKLOADARGS/'$workload'/g' simulator/test_filled_$workload.v
    chmod +x simulator/test_filled_$workload.v
    
    ##### compile file
    iverilog -Wall -pARRAY_SIZE_LIMIT=368435456  -osimulator/sim_$workload.vvp  \
    core.v decode.v execute.v fetch.v storagemgmt.v writeBack.v \
    simulator/test_filled_$workload.v

    ##### runsimlation
    echo "running workload $workload........."
    vvp -MmyVpi -mtc simulator/sim_$workload.vvp
    echo "finish workload $workload............................................"
    echo ""
    echo ""
    echo ""



done