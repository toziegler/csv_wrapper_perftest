#!/bin/bash
device="null"
client=0
server=0
server_ip=null
fabric="null"
protocol="null"

NUMBER_RUNS=3
NUMBER_ITERATIONS=50000

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
    run_experiment "numactl --cpubind=0 ./perftest/ib_send_lat -a -d ${device} -n ${NUMBER_ITERATIONS} -R -F --perform_warm_up -c ${protocol}" $sleep # latency
    exit 1
}

client(){
    sleep=3 # ensures that server starts before client
    # latency 
    run_experiment "bash wrapper_ib_send_lat.sh -e latency -d ${device} -p ${protocol} -c -a ${server_ip} -n ${NUMBER_ITERATIONS} -f ${fabric}" $sleep
    # latency inline
    run_experiment "bash wrapper_ib_send_lat.sh -e latency -d ${device} -p ${protocol} -c -a ${server_ip} -n ${NUMBER_ITERATIONS} -f ${fabric} -i 220" $sleep
    # bw 1 1
    # tx depth
    # cq moderation
    # multiple queues 
    exit 1
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
