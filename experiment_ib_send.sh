#!/bin/bash
device="null"
client=0
server=0
server_ip=null
fabric="null"
protocol="null"

# NUMBER_RUNS=3
NUMBER_RUNS=1
NUMBER_ITERATIONS=50000
# NUMBER_ITERATIONS=10000

TX_DEPTHS=( 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384)
CQ_MODS=( 1 2 4 8 16 32 64 128 256 512 1024)
# NUMBER_QS=( 1 2 4 8)
# POST_LIST=( 1 2 4 8)

declare -A PERFTEST_PATH=( ["IB"]="./perftest/" ["EFA"]="/opt/perftest/bin/")
declare -A ADDITIONAL_FLAGS=( ["IB"]="-R" ["EFA"]="-x 0")
declare -A INLINE_SIZE=( ["IB"]="220" ["EFA"]="32")

help(){
    echo "Usage:  TODO " >&2
    echo
    echo
    exit 1
}


# run experiment 3 times 
run_experiment(){

    for ((c=0; c<${NUMBER_RUNS}; c++))
    do
        echo "RUN $c"
        echo "$1"
        $1
        sleep $2
    done
    
}

server(){
    sleep=1

    # latency 
    run_experiment "numactl --cpubind=0 ${PERFTEST_PATH[${fabric}]}ib_send_lat -a -d ${device} -n ${NUMBER_ITERATIONS} ${ADDITIONAL_FLAGS[${fabric}]} -F --perform_warm_up -c ${protocol}" $sleep # latency

    # latency inline
    run_experiment "numactl --cpubind=0 ${PERFTEST_PATH[${fabric}]}ib_send_lat -a -d ${device} -n ${NUMBER_ITERATIONS} ${ADDITIONAL_FLAGS[${fabric}]} -F --perform_warm_up -c ${protocol}" $sleep # latency

    # sync bw 
    run_experiment "numactl --cpubind=0 ${PERFTEST_PATH[${fabric}]}ib_send_bw -a -d ${device} -n ${NUMBER_ITERATIONS} ${ADDITIONAL_FLAGS[${fabric}]} -F -c ${protocol}" $sleep # bw

    # # increase the number of outstanding I/Os
    # for i in "${TX_DEPTHS[@]}"
    # do
	#     echo "tx depth $i"
    #     run_experiment "numactl --cpubind=0 ${PERFTEST_PATH[${fabric}]}ib_send_bw -a -d ${device} -n ${NUMBER_ITERATIONS} ${ADDITIONAL_FLAGS[${fabric}]} -F -c ${protocol}" $sleep # bw
    # done
    
    # # decrease the number of completion events take maximum number of tx completions
    # # cq moderation
    # for i in "${CQ_MODS[@]}"
    # do
	#     echo "cq mod $i"
    #     run_experiment "numactl --cpubind=0 ${PERFTEST_PATH[${fabric}]}ib_send_bw -a -d ${device} -n ${NUMBER_ITERATIONS} ${ADDITIONAL_FLAGS[${fabric}]} -F -c ${protocol}" $sleep # bw
    # done

    # Grid search
    for i in "${TX_DEPTHS[@]}"
    do
        for j in "${CQ_MODS[@]}"
        do
            run_experiment "numactl --cpubind=0 ${PERFTEST_PATH[${fabric}]}ib_send_bw -a -d ${device} -n ${NUMBER_ITERATIONS} ${ADDITIONAL_FLAGS[${fabric}]} -F -c ${protocol}" $sleep # bw  
        done
    done
    
    # run experiment with multiple queues 
    
    exit 1
}

client(){
    sleep=3 # ensures that server starts before client

    # latency 
    run_experiment "bash wrapper_ib_send_lat.sh -e latency -d ${device} -p ${protocol} -c -a ${server_ip} -n ${NUMBER_ITERATIONS} -f ${fabric}" $sleep

    # latency inline
    run_experiment "bash wrapper_ib_send_lat.sh -e latency_inline -d ${device} -p ${protocol} -c -a ${server_ip} -n ${NUMBER_ITERATIONS} -f ${fabric} -i ${INLINE_SIZE[${fabric}]}" $sleep

    # bw 1 1
    run_experiment "bash wrapper_ib_send_bw.sh -e bw_sync -d ${device} -p ${protocol} -c -a ${server_ip} -n ${NUMBER_ITERATIONS} -f ${fabric} -t 1 -m 1 -l 1 -q 1" $sleep

    # # tx depth
    # for i in "${TX_DEPTHS[@]}"
    # do
	#     echo "tx depth $i"
    #     run_experiment "bash wrapper_ib_send_bw.sh -e bw_tx_depth -d ${device} -p ${protocol} -c -a ${server_ip} -n ${NUMBER_ITERATIONS} -f ${fabric} -t ${i} -m 1 -l 1 -q 1" $sleep
    # done

    # # cq moderation
    # for i in "${CQ_MODS[@]}"
    # do
	#     echo "cq mod $i"
    #     run_experiment "bash wrapper_ib_send_bw.sh -e bw_cq_mod -d ${device} -p ${protocol} -c -a ${server_ip} -n ${NUMBER_ITERATIONS} -f ${fabric} -t 1024 -m ${i} -l 1 -q 1" $sleep
    # done

    #Grid Search
    for i in "${TX_DEPTHS[@]}"
    do
        for j in "${CQ_MODS[@]}"
        do
	    echo "tx depth $i"
        run_experiment "bash wrapper_ib_send_bw.sh -e bw_tx_cq_grid -d ${device} -p ${protocol} -c -a ${server_ip} -n ${NUMBER_ITERATIONS} -f ${fabric} -t ${i} -m ${j} -l 1 -q 1" $sleep
        done
    done

    # multiple queues

    # standard configuration or best performing
    
    
}

main(){
    #--------------------------------------------------        
    while getopts d:a:f:p:sch flag
    do
        case "${flag}" in
            d) device=${OPTARG};;
            p) protocol=${OPTARG};;
            a) server_ip=${OPTARG};;
            f) fabric=${OPTARG};;
            s) server=1;;
            c) client=1;;
            h) ;&
            *) help;;
        esac
    done
    #--------------------------------------------------
    if [[ "$device" == "null" ]] ; then
        echo 'Missing mandatory parameters -d or -p -e' >&2
        help
        exit 1
    fi
    #--------------------------------------------------
    echo "Choosen Parameters"
    echo "device: $device";
    echo "server: $server";
    echo "client: $client";
    echo "fabric: $fabric";
    echo "protocol: $protocol";
    #--------------------------------------------------
    # client
    if [[ "$client" == 1 ]]; then
        if [[ "$server_ip" == "null" ]]; then
            echo 'Missing server ip' >&2
            help
            exit 1
        fi
        client
    fi
    #--------------------------------------------------
    # server
    if [[ "$server" == 1 ]]; then
        server 
    fi
}

main "${@}"
