#!/bin/bash

if [ -d vsim ]
then
rm -rf vsim
fi

mkdir vsim
cd vsim

vsim -do ../do_files/vsim.do