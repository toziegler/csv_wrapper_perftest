#!/bin/bash

# define defaults if possbile 
experiment="null"
device="null"
protocol="null"
tx_depth=1;
rx_depth=1;
cq_moderation=1
post_list=1
number_qp=1
inline_size=0
number_iterations=10000
client=0
server=0
fabric="null"
server_ip=null

FILE="null" # will be constructed based on experiment name

declare -A PERFTEST_PATH=( ["IB"]="./perftest/" ["EFA"]="/opt/perftest/bin/")
declare -A ADDITIONAL_FLAGS=( ["IB"]="-R" ["EFA"]="-x 0")
declare -A LINES=( ["IB"]="+18" ["EFA"]="20")

help(){
    echo "Usage:  TODO " >&2
    echo
    echo
    exit 1
}

server(){
    echo "starting server"

    exit 1
    # if [ -f "$FILE" ]; then
    #     echo "$FILE exists."
    # else
    #     echo "experiment,measurement,device,protocol,txdepth,rxdepth,cqmoderation,postlist,numberqps,inline,iters,server,client,bytes,iterations,bwpeak,bwavg,msgrate" | tee -a bw_benchmark.csv
    # fi

    # numactl --cpubind=0 ./perftest/ib_send_bw  -d ${device} -a -n ${number_iterations} -R -F -r ${rx_depth} -Q ${cq_moderation} -q ${number_qp} -l ${post_list} -I ${inline_size} | grep -v "^ local" | grep -v "^ remote" | tail -n +20 |sed 's/\s\+/,/g' | sed 's/-\+//g' | sed "s/^/${experiment},bw,${device},${protocol},${tx_depth},${rx_depth},${cq_moderation},${post_list},${number_qp},${inline_size},${number_iterations},${server},${client}/" | head -n -1      
    # exit 1
}

client(){
    echo "starting client"

    if [ -f "$FILE" ]; then
        echo "$FILE exists."
    else
        echo "experiment,measurement,device,protocol,txdepth,rxdepth,cqmoderation,postlist,numberqps,inline,iters,server,client,bytes,iterations,bwpeak,bwavg,msgrate" | tee -a $FILE
    fi

    echo "numactl --cpubind=0 ${PERFTEST_PATH[${fabric}]}ib_send_bw  -d ${device} -a -n ${number_iterations} ${ADDITIONAL_FLAGS[${fabric}]} -F -t ${tx_depth} -Q ${cq_moderation} -q ${number_qp} -l ${post_list} -I ${inline_size} -c ${protocol} ${server_ip}"
    
    numactl --cpubind=0 ${PERFTEST_PATH[${fabric}]}ib_send_bw  -d ${device} -a -n ${number_iterations} ${ADDITIONAL_FLAGS[${fabric}]} -F -t ${tx_depth} -Q ${cq_moderation} -q ${number_qp} -l ${post_list} -I ${inline_size} -c ${protocol} ${server_ip} | grep -v "^ local" | grep -v "^ remote" | tail -n ${LINES[${fabric}]} |sed 's/\s\+/,/g' | sed 's/-\+//g' | sed "s/^/${experiment},bw,${device},${protocol},${tx_depth},${rx_depth},${cq_moderation},${post_list},${number_qp},${inline_size},${number_iterations},${server},${client}/" | head -n -1 | tee -a $FILE    
    exit 1
}

main(){
    #--------------------------------------------------        
    while getopts d:p:t:r:m:l:q:i:a:n:e:f:sch flag
    do
        case "${flag}" in
            e) experiment=${OPTARG};;
            d) device=${OPTARG};;
            p) protocol=${OPTARG};;
            t) tx_depth=${OPTARG};;
            r) rx_depth=${OPTARG};;
            m) cq_moderation=${OPTARG};;
            l) post_list=${OPTARG};;
            q) number_qp=${OPTARG};;
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
    echo "tx_depth: $tx_depth"; 
    echo "rx_depth: $rx_depth";
    echo "cq_moderation: $cq_moderation";
    echo "post_list: $post_list";
    echo "number_qp: $number_qp";
    echo "inline_size: $inline_size";
    echo "number_iterations: $number_iterations";
    echo "fabric: $fabric";
    echo "server: $server";
    echo "client: $client";
    #--------------------------------------------------
    FILE="./csv/${fabric}_bw_benchmark.csv"
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
