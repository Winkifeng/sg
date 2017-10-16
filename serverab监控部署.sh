#！/bin/bash
setenforce 0 &> /dev/null && echo "防火墙已关闭"
ssh-copy-id root@172.25.5.11 &> /dev/null && echo "密钥已推送"
yum -y install lftp &> /dev/null
lftp 172.25.254.250:/notes/project/UP200/UP200_cacti-master> mirror pkg/ &> /dev/null
yum -y install httpd php php-mysql mariadb-server mariadb &> /dev/null && echo "mariadb安装完成"
cd pkg/
yum localinstall cacti-0.8.8b-7.el7.noarch.rpm php-snmp-5.4.16-23.el7_0.3.x86_64.rpm &> /dev/null && echo "snmp安装完成"
service mariadb start &> /dev/null && echo "mariadb已启动"
mysql -e "create database cacti ;grant all on cacti.* to cactidb@'localhost' identified by '123456';flush privileges;"
sed -i 's/^$database_username =.*/$database_username = "cactidb";/' /etc/cacti/db.php
sed -i 's/^$database_password =.*/$database_password = "123456";/' /etc/cacti/db.php
mysql -ucactidb -p123456 cacti < /usr/share/doc/cacti-0.8.8b/cacti.sql
sed -i 's/Require host localhost/Require all granted/' /etc/httpd/conf.d/cacti.conf
timedatectl set-timezone Asia/Shanghai
sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/' /etc/php.ini &> /dev/null && echo "时区已修改"
cat > /etc/cron.d/cacti << END
*/5 * * * *     cacti   /usr/bin/php /usr/share/cacti/poller.php > /dev/null 2>&1
END
service httpd restart &> /dev/null && echo "httpd已重启"
service snmpd start &> /dev/null && echo "snmpd已启动"
netstat -anlp |grep :161
rsync -avzR /etc/snmp/snmpd.conf 172.25.5.11:/
ssh root@172.25.5.11 "setenforce 0" &> /dev/null && echo "防火墙已关闭"
ssh root@172.25.5.11 "yum -y install net-snmp" &> /dev/null && echo "snmp已安装"
ssh root@172.25.5.11 "service snmpd start" &> /dev/null && echo "snmp已启动"
 
