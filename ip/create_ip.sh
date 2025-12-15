#!/bin/bash
echo ------------------------------
echo       Generate IP gausse filter
echo ------------------------------

# Clean previous projects
if [ -d .Xil ] 
then
	rm -rf .Xil
fi

if [ vivado.jou ] 
then
	rm -rf vivado.jou
fi

if [ vivado.log ] 
then
	rm -rf vivado.log
fi


# run synthesis
vivado -mode batch -source create_ip.tcl


if [ $? -gt 0 ] 
 then 
    echo !!!! ERROR IP gausse filter !!!   
    read -s -n 1 -p "Press any key to continue . . ."  
    exit 1
 else 
    echo IP gausse filter Generate IP ok
fi
