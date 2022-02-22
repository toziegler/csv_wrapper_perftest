#!/bin/bash

cd perftest
./autogen.sh 
./configure
make -j
cd ..
