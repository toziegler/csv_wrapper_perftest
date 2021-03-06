#!/bin/bash

# define defaults if possbile 
experiment="null"
device="null"
protocol="null"
inline_size=0
number_iterations=10000
client=0
server=0
server_ip=null
fabric="null"
FILE="null" # will be constructed based on experiment name

declare -A PERFTEST_PATH=( ["IB"]="./perftest/" ["EFA"]="/opt/perftest/bin/")
declare -A ADDITIONAL_FLAGS=( ["IB"]="-R" ["EFA"]="-x 0")
declare -A LINES=( ["IB"]="+17" ["EFA"]="+20")

help(){
    echo "Usage:  TODO " >&2
    echo
    echo
    exit 1
}

server(){
    echo "starting server"

    # exit 1
    # if [ -f "$FILE" ]; then
    #     echo "$FILE exists."
    # else
    #     echo "experiment,measurement,device,protocol,txdepth,rxdepth,cqmoderation,postlist,numberqps,inline,iters,server,client,bytes,iterations,bwpeak,bwavg,msgrate" | tee -a bw_benchmark.csv
    # fi

    # numactl --membind=0 taskset -c 0 ./perftest/ib_send_bw  -d ${device} -a -n ${number_iterations} -R -F -r ${rx_depth} -Q ${cq_moderation} -q ${number_qp} -l ${post_list} -I ${inline_size} | grep -v "^ local" | grep -v "^ remote" | tail -n +20 |sed 's/\s\+/,/g' | sed 's/-\+//g' | sed "s/^/${experiment},bw,${device},${protocol},${tx_depth},${rx_depth},${cq_moderation},${post_list},${number_qp},${inline_size},${number_iterations},${server},${client}/" | head -n -1      
    exit 1
}

client(){
    echo "starting client"

    if [ -f "$FILE" ]; then
        echo "$FILE exists."
    else
        echo "experiment,measurement,device,protocol,inline,iters,server,client,bytes,iterations,min,max,typical,avg,stddev,99percentile,999percentile" | tee -a $FILE
    fi

    echo "numactl --membind=0 taskset -c 0 ${PERFTEST_PATH[${fabric}]}ib_send_lat  -d ${device} -a -n ${number_iterations} ${ADDITIONAL_FLAGS[${fabric}]} -F -I ${inline_size} -c ${protocol} ${server_ip} --perform_warm_up"
    
    numactl --membind=0 taskset -c 0 ${PERFTEST_PATH[${fabric}]}ib_send_lat  -d ${device} -a -n ${number_iterations} ${ADDITIONAL_FLAGS[${fabric}]} -F -I ${inline_size} -c ${protocol} ${server_ip} --perform_warm_up | grep -v "^ local" | grep -v "^ remote" | tail -n ${LINES[${fabric}]} |sed 's/\s\+/,/g' | sed 's/-\+//g' | sed "s/^/${experiment},lat,${device},${protocol},${inline_size},${number_iterations},${server},${client}/" | head -n -1 | sed 's/\(.*\),/\1 /' | tee -a $FILE # last set removes additional commata
    exit 1
}

main(){
    #--------------------------------------------------        
    while getopts d:p:i:a:n:e:f:sch flag
    do
        case "${flag}" in
            e) experiment=${OPTARG};;
            d) device=${OPTARG};;
            p) protocol=${OPTARG};;
            i) inline_size=${OPTARG};;
            n) number_iterations=${OPTARG};;
            a) server_ip=${OPTARG};;
            f) fabric=${OPTARG};;
            s) server=1;;
            c) client=1;;
            h) ;&
            *) help;;
        esac
    done
    #--------------------------------------------------
    if [[ "$device" == "null" ]] || [[ "$protocol" == "null" ]] || [[ "$experiment" == "null" ]] || [[ "$fabric" == "null" ]]; then
        echo 'Missing mandatory parameters -d or -p -e -f' >&2
        help
        exit 1
    fi
    #--------------------------------------------------
    echo "Choosen Parameters"
    echo "device: $device";
    echo "protocol: $protocol";
    echo "inline_size: $inline_size";
    echo "number_iterations: $number_iterations";
    echo "server: $server";
    echo "client: $client";
    #--------------------------------------------------
    FILE="./csv/${fabric}_lat_benchmark.csv"
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

exit 0
