#!/bin/bash

git submodule update --init --recursive
cd perftest
./autogen.sh 
./configure
make -j
cd ..
