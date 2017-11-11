#!/usr/bin/python
#encording=utf-8
import telnetlib
import sys, getopt
import time
import os
import subprocess

def do_telnet(hostip, username, passwd, finish, cmds):

    tn=telnetlib.Telnet(hostip, port=23, timeout=10)
    tn.set_debuglevel(0)

    tn.read_until('User Name:')
    tn.write(username + '\n')

    tn.read_until('Password:')
    tn.write(passwd + '\n')
 
    tn.read_until(finish)
    for cmd in cmds:
        tn.write('%s\n'% cmd)

    tn.read_until(finish)
    tn.close()

def get_timestamp():
    timestamp = time.time()
    timestruct = time.localtime(timestamp)
    return time.strftime('%Y-%m-%d_%H:%M:%S', timestruct) 

def show_help():
    print "\n   ================================================================\n";
    print "    powerbar.pl --ibar=192.168.1.188 --ip=192.168.1.1,192.168.1.2,192.168.1.3,192.168.1.4\n";
    print "    ================================================================\n";


def mkdir(path):
    path = path.strip()
    path = path.rstrip("\\")
    
    is_exists = os.path.exists(path)
    
    if not is_exists:
        os.makedirs(path)
        print("Make "+path+" successfully.")
        return True
    else:
        print(path+" is existed.")
        return False


def is_online(ip):
    cmd = "ping -c %d %s" % (1, ip)
    p = subprocess.Popen(args=cmd, shell=True, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
    p.wait()
    (stdoutput, erroutput) = p.communicate()
    return stdoutput.find("1 received") >= 0

def get_sel_from_bmc(cnt, ip, filename):
    fo=open(filename, "a+", 0)
    fo.write("===========Cycle " + str(cnt) + "===========\n")
    fo.close()
    cmd = "ipmitool -I lan -H "+ip+" -U ADMIN -P ADMIN sel elist >>\""+ filename +"\""
    p=subprocess.Popen(args=cmd, shell=True, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
    p.wait()
    cmd = "ipmitool -I lan -H "+ip+" -U ADMIN -P ADMIN sel clear >>\""+ filename +"\""
    p=subprocess.Popen(args=cmd, shell=True, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
    p.wait()
    
def check_file_lines(filename):
    fo=open(filename, "r", 0)
    count=len(fo.readlines())
    fo.close()
    return count

if __name__ == '__main__':
    bmcip=[]
    bmclogdir=[]
    powercycletimes=220
    creat_if_groups_cmd=["set group wk420 all yes"]
    poweron_cmd=["set group wk420 on"]
    poweroff_cmd=["set group wk420 off"]
    ibar="192.68.32.188"
    username="admin"
    password="admin"
    finish="iBootBar >"
    dirname="test_"+get_timestamp()
    loggingfile=dirname+r"/server_log.log"
    clientlog=[]
    i=1
    opts, args = getopt.getopt(sys.argv[1:],"hi:", ["h","help","ibar=","ip="])
    for op, value in opts:
        if op == "--h" or op == "--help":
            show_help()
            sys.exit()
        elif op == "--ibar":
            ibar=value
        elif op == "--ip":
            ips=value.split(",")
            for ip in ips:
                bmcip.append(ip)
                clientlog.append("PC"+str(i)+".log")
                bmclogdir.append(dirname+r"/bmc"+str(i)+"/bmc.log")
                mkdir(dirname+r"/bmc"+str(i))
                i+=1

    mkdir(dirname);
    f=open(loggingfile, "a+", 0)
   
    do_telnet(ibar, username, password, finish, creat_if_groups_cmd)
    do_telnet(ibar, username, password, finish, poweroff_cmd)
    time.sleep(30)

    for count in range(1, powercycletimes+1):
        f.write(get_timestamp()+": Test Cycle: "+str(count)+" Start... \n")
        f.write(get_timestamp()+": Power up all outlets...\n")
        do_telnet(ibar, username, password, finish, poweron_cmd)
        time.sleep(240)

        for i in range(0, len(bmcip)):
            if not is_online(bmcip[i]):
                f.write(get_timestamp()+": BMC IP address "+bmcip[i]+" is not online.\n")
            else:
                get_sel_from_bmc(count, bmcip[i], bmclogdir[i])
            
            if check_file_lines(clientlog[i]) == count:
                f.write(get_timestamp()+": "+bmcip[i]+" Power Cycle Pass\n")
            else:
                f.write(get_timestamp()+": "+bmcip[i]+" Power Cycle Fail\n")

        f.write(get_timestamp()+": Power down all outlets...\n") 
        do_telnet(ibar, username, password, finish, poweroff_cmd)
        time.sleep(40)
    f.close()
