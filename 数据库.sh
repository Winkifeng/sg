#!/bin/bash
iptables -F && echo "防火墙已关闭"
yum -y install bind &> /dev/null && echo "bind已安装"
cat > /etc/named.conf << END
options {
listen-on port 53 { 127.0.0.1; any; };
listen-on-v6 port 53 { ::1; };
directory "/var/named";
dump-file "/var/named/data/cache_dump.db";
statistics-file "/var/named/data/named_stats.txt";
memstatistics-file "/var/named/data/named_mem_stats.txt";
allow-query { localhost; any; };
recursion yes;
dnssec-enable yes;
dnssec-validation yes;
bindkeys-file "/etc/named.iscdlv.key";
managed-keys-directory "/var/named/dynamic";
pid-file "/run/named/named.pid";
session-keyfile "/run/named/session.key";
};
logging {
channel default_debug {
file "data/named.run";
severity dynamic;
};
};
view "php" {
match-clients { 172.25.5.0/24; };
zone "." IN {
type hint;
file "named.ca";
};
zone "php-f5.com" IN {
type master;
file "php-f5.com.zone";
};
include "/etc/named.rfc1912.zones";
};
view "jsp" {
match-clients { 172.25.254.0/24; };
zone "." IN {
type hint;file "named.ca";
};
zone "jsp-f5.com" IN {
type master;
file "jsp-f5.com.zone";
};
include "/etc/named.rfc1912.zones";
};
include "/etc/named.root.key";
END

cat > /var/named/jsp-f5.com.zone << END
/$TTL 1D
@ IN SOA ns1.jsp-f5.com. nsmail.jsp-f5.com. (
10 ; serial
1D ; refresh
1H ; retry
1W ; expire
3H ) ; minimum
@ NS ns1.jsp-f5.com.
ns1 A 172.25.254.221
www A 172.25.5.11
END

cat > /var/named/php-f5.com.zone << END
/$TTL 1D
@ IN SOA ns1.php-f5.com. nsmail.php-f5.com. (
10 ; serial
1D ; refresh
1H ; retry
1W ; expire
3H ) ; minimum
@ NS ns1.php-f5.com.
ns1 A 172.25.254.221
www A 172.25.5.10
END

yum -y install mariadb-server mariadb &> /dev/null && echo "mariadb已安装"
systemctl start mariadb && echo "mariadb已启动"
systemctl enable mariadb && echo "已设置开机启动"

mysql -e "delete from mysql.user where user='';"
mysql -e "update mysql.user set password=password('uplooking') where user='root';"
mysql -e "flush privileges;"
mysql -e "create database bbs default charset utf8;"
mysql -e "create database jsp default charset utf8;"
mysql -e "grant all on bbs.* to runbbs@'%' identified by '123456';"
mysql -e "grant all on jsp.* to runjsp@'%' identified by '123456';"
mysql -e "flush privileges;" && echo "数据库已刷新"

yum -y install nfs-utils &> /dev/null && echo "nfs已安装"
cat >> /etc/exports << END
/webroot 172.25.5.0/24(rw,sync,no_root_squash)
END

mkdir /webroot && echo "webroot目录已创建"
chmod 777 /webroot/
service nfs restart && echo "nfs已重启"
service rpcbind restart && echo "rpc已重启"
wget
ftp://172.25.254.250/notes/project/software/lnmp/Discuz_X3.1_SC_UTF8.zip &> /dev/null && echo "UTF8压缩包已下载"
wget ftp://172.25.254.250/notes/project/software/tomcat/ejforum-2.3.zip &> /dev/null && echo "ejforum压缩包已下载"
unzip Discuz_X3.1_SC_UTF8.zip &> /dev/null && echo "UTF8已解压"
mv upload/ /webroot/bbs
unzip ejforum-2.3.zip &> /dev/null && echo "ejforum已解压"
mv ejforum-2.3/ejforum/ /webroot/jsp
