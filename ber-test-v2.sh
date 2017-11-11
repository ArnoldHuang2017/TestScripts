#!/bin/bash

#Author : Arnold Huang
#Version: 2.0
#History:

devname=$1

if [ !  -e $devname  -o "$devname" == "" ]
then
    echo "The device $devname is not existed!"
    exit
fi

mkdir -p ./$devname

device_model=`smartctl -a $devname |grep -i "device model"|awk -F':' '{print $2}'| grep -o "[^ ]\+\( \+[^ ]\+\)*"`
device_sn=`smartctl -a $devname |grep -i "serial number"|awk -F':' '{print $2}'`
echo -en "============================\nTarget Hard Drive Info:\n"
echo "Model:"$device_model
echo "S/N:  "$device_sn


function check_sata_speed()
{
    sataport=`dmesg|grep -i "$1"|awk '{print $3}'|awk -F'.' '{print $1}'|tail -n 1`
    sataspeed=`dmesg|grep -i "$sataport" |grep -i gbps|awk '{print $7}'|tail -n 1`
    if [ "$sataspeed" != "6.0" ]
    then
        echo "The DUT doesn't work on SATA3"
    else
        echo "The DUT works on SATA3"
    fi 
}   

if [ $devname != "/dev/sda" ]
then
    output_path=/mnt${devname}1
    umount ${output_path} 2>/dev/null
    echo ====Mount the file system====
    mkdir -p ${output_path}
    #mkfs.ext4 ${devname}1 >/dev/null 2>/dev/null
    mount ${devname}1 ${output_path}
else
    output_path=/home/
fi

if [ ! -e /mnt/ram/test.iso ]
then
   mkdir /mnt/ram 2>/dev/null >/dev/null
   mount -t ramfs none /mnt/ram
   cp test.iso /mnt/ram/test.iso
fi

udma_error_bef=`smartctl -a $devname |grep -i "UDMA_CRC_Error_Count"|awk '{print $10}'`
echo -en "============================\nUDMA_CRC_Error_Count before the BER test:\t$udma_error_bef\n"



echo ====Start the writing testing on `date`=======
#11641.5GB, 48GB per cycle, 242.5cycles.
cycle=1


while [ $cycle -le 243 ]
do
     echo ==Cycle $cycle==
     cnt=1
     check_sata_speed "$device_model"
     rm ${output_path}/test_* 2>/dev/null
     while [ $cnt -le 12 ] 
     do
       dd if=/mnt/ram/test.iso of=$output_path/test_$cnt.iso bs=1M count=4096 conv=fdatasync >>./$devname/write.log 2>>./$devname/write.log
       sync
       cnt=`expr $cnt + 1`
     done 
     cycle=`expr $cycle + 1`
     check_sata_speed "$device_model"
     dmesg > ./$devname/dmesg.log
done

echo =====Finish the write test on `date`====

udma_error_after=`smartctl -a $devname |grep -i "UDMA_CRC_Error_Count"|awk '{print $10}'`

echo -en "============================\nUDMA_CRC_Error_Count after the write BER test:\t$udma_error_after\n"

if [ $udma_error_bef -ne $udma_error_after ]
then
   echo "Write Test is failed, UDMA CRC ERROR ocurred!!!!"
else
   echo "Write Test is passed, no UDMA CRC ERROR!^_^"
fi


echo ====Start the reading testing on `date`=======
#11641.5GB, 48GB per cycle, 242.5cycles.
cycle=1

udma_error_bef=`smartctl -a $devname |grep -i "UDMA_CRC_Error_Count"|awk '{print $10}'`
echo -en "============================\nUDMA_CRC_Error_Count before the read BER test:\t$udma_error_bef\n"
while [ $cycle -le 243 ]
do
     echo ==Cycle $cycle==
     cnt=1
     check_sata_speed "$device_model"
     while [ $cnt -le 12 ] 
     do
       dd if=$output_path/test_$cnt.iso of=/dev/null bs=1M count=4096 conv=sync >>./$devname/read.log 2>>./$devname/read.log
       sync
       cnt=`expr $cnt + 1`
     done 
     cycle=`expr $cycle + 1`
     check_sata_speed "$device_model"
     dmesg > ./$devname/dmesg.log
    
done

echo =====Finish the read test on `date`====

udma_error_after=`smartctl -a $devname |grep -i "UDMA_CRC_Error_Count"|awk '{print $10}'`

echo -en "============================\nUDMA_CRC_Error_Count after the read BER test:\t$udma_error_after\n"

if [ $udma_error_bef -ne $udma_error_after ]
then
   echo "Read Test is failed, UDMA CRC ERROR ocurred!!!!"
else
   echo "Read Test is passed, no UDMA CRC ERROR!^_^"
fi

