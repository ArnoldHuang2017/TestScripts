#!/bin/sh

[ -f /etc/init.d/functions ] && . /etc/init.d/functions


function net(){
b0=-1
cat /proc/net/dev|grep ":"|grep -v "lo"|cut -d: -f1 |sort > /tmp/net_name.txt
cat /tmp/net_name.txt|while read line
do
c0=$line
b0=`expr $b0 + 1`
mv /etc/sysconfig/network-scripts/ifcfg-$c0 /etc/sysconfig/network-scripts/ifcfg-eth$b0
sed -i 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-eth$b0
sed -i '/IPV6/d' /etc/sysconfig/network-scripts/ifcfg-eth$b0
sed -i 's/'$c0'/eth'$b0'/g' /etc/sysconfig/network-scripts/ifcfg-eth$b0
done < /tmp/net_name.txt
}

function grub(){
sed -i 's/crashkernel=auto rhgb quiet/crashkernal=auto net.ifnames=0 biosdevname=0 rhgb quiet/g' /etc/default/grub
grub2-mkconfig -o /boot/grub/grub.cfg
}

function rules(){
b0=-1
lshw -c network|egrep "logical name"|awk -F " " '{print $3}'|while read line
do
  a0=$line
  b0=`expr $b0 + 1`
  c0=`lshw -c network |egrep -C 2 $a0|egrep serial|awk -F " " '{print $2}'`
  d0=`lshw -c network |egrep -C 2 $a0|egrep "bus info" | awk -F "@" '{print $2}'`
  echo 'ACTION=="add", SUBSYSTEM=="net", BUS=="pci", ATTR{address}=="'$c0'", ID="'$d0'",NAME="eth'$b0'"' >> /etc/udev/rules.d/70-persistent-net.rules
  sed -i '$a HWADDR='$c0'' /etc/sysconfig/network-scripts/ifcfg-eth$b0
done
}

yum -y install net-tools smartmontools psmisc lshw
net
grub
rules

