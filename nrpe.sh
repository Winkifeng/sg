#!/bin/bash
setenforce 0 && echo "防火墙已关闭"
lftp 172.25.254.250:/notes/project/UP200/UP200_nagios-master> mirror pkg/
cd pkg/
yum localinstall *.rpm &> /dev/null && echo "rpm包已安装"
yum -y localinstall *.rpm &> /dev/null
yum -y install lftp &> /dev/null && echo "lftp已安装"
lftp 172.25.254.250:/notes/project/software/nagios> get nrpe-2.12.tar.gz
tar -xf nrpe-2.12.tar.gz && echo "压缩包已解压"
yum -y install gcc &> /dev/null && echo "gcc已安装"
yum -y install xinetd &> /dev/null && echo "xinetd已安装"
yum -y install openssl-devel &>/dev/null && echo "ssl包已安装"
cd nrpe-2.12/
./configure &> /dev/null && echo "编译完成"
make all &> /dev/null && echo "make完成"
make install-plugin
make install-daemon
make install-daemon-config
make install-xinetd
sed -i 's/only_from       = */only_from       = 127.0.0.1 172.25.1.10/' /etc/xinetd.d/nrpe 
cat >> /etc/services << END
nrpe            5666/tcp                # nrpe
END
cat > /usr/local/nagios/etc/nrpe.cfg << END
erver_port=5666
nrpe_user=nagios
nrpe_group=nagios
allowed_hosts=127.0.0.1
dont_blame_nrpe=0
debug=0
command_timeout=60
connection_timeout=300
command[check_users]=/usr/local/nagios/libexec/check_users -w 5 -c 10
command[check_load]=/usr/local/nagios/libexec/check_load -w 15,10,5 -c 30,25,20
command[check_hda1]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /dev/hda1
command[check_zombie_procs]=/usr/local/nagios/libexec/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/local/nagios/libexec/check_procs -w 150 -c 200 

command[check_uu]=/usr/lib64/nagios/plugins/check_users -w 5 -c 10
command[check_ll]=/usr/lib64/nagios/plugins/check_load -w 15,10,5 -c 30,25,20
command[check_root]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_zombie_procs]=/usr/lib64/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/lib64/nagios/plugins/check_procs -w 150 -c 200 
command[check_haha]=/usr/lib64/nagios/plugins/check_swap -w 20% -c 10%
END
/usr/local/nagios/libexec/check_nrpe -H localhost
ssh root@172.25.5.10 "cd /etc/nagios/objects/"
ssh root@172.25.5.10 "cat  >> /etc/nagios/objects/commands.cfg << END
define command{
        command_name check_nrpe
        command_line $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
END"
ssh root@172.25.5.10 "cat > /etc/nagios/objects/serverb.cfg << END
define host{
        use                     linux-server                                                         
        host_name               serverb.pod1.example.com
        alias                   serverb1
        address                 172.25.5.11
        }
define hostgroup{
        hostgroup_name  uplooking-servers 
        alias           uplooking 
        members         serverb.pod1.example.com     
        }
# 定义监控服务
define service{
        use generic-service
        host_name serverb.pod5.example.com
        service_description load
        check_command check_nrpe!check_users
}
define service{
        use generic-service
        host_name serverb.pod5.example.com
        service_description user
        check_command check_nrpe!check_load
}

define service{
        use generic-service
        host_name serverb.pod5.example.com
        service_description root
        check_command check_nrpe!check_hda1
}

define service{
        use generic-service
        host_name serverb.pod5.example.com
        service_description zombie
        check_command check_nrpe!check_zombie_procs
}



define service{
        use generic-service
        host_name serverb.pod5.example.com
        service_description procs
        check_command check_nrpe!check_total_procs
}

END"
ssh root@172.25.5.10 "cat >> /etc/nagios/nagios.cfg << END
cfg_file=/etc/nagios/objects/serverb.cfg
END"
ssh root@172.25.5.10 "nagios -v /etc/nagios/nagios.cfg"
ssh root@172.25.5.10 "/usr/lib64/nagios/plugins/check_nrpe -H 172.25.5.11"
ssh root@172.25.5.10 "/usr/lib64/nagios/plugins/check_nrpe -H 172.25.1.11 -c check_users"
ssh root@172.25.5.10 "systemctl restart nagios"
