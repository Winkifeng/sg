#!/bin/bash
setenforce 0 
iptables -F
yum -y install php php-mysql &> /dev/null && echo "php已安装"
rpm -ivh ftp://172.25.254.250/notes/project/UP200/UP200_nginx-master/pkg/nginx-1.8.1-1.el7.ngx.x86_64.rpm &> /dev/null && echo "ngx已安装"
rpm -ivh ftp://172.25.254.250/notes/project/UP200/UP200_nginx-master/pkg/spawn-fcgi-1.6.3-5.el7.x86_64.rpm &> /dev/null && echo "fcgi已安装"
cat > /etc/nginx/nginx.conf << END
worker_processes 2;
events {
use epoll;
worker_connections 1024;
}
END
cat > /etc/nginx/conf.d/www.php-f5.com.conf << END
server {
listen 80;
server_name www.php-f5.com;
root /usr/share/nginx/php-f5.com;
index index.php index.html index.htm;
location ~ \.php$ {
fastcgi_pass 127.0.0.1:9000;
fastcgi_index index.php;
fastcgi_param SCRIPT_FILENAME /usr/share/nginx/php-f5.com$fastcgi_script_name;
include fastcgi_params;
}
}
END
mkdir -p /usr/share/nginx/php-f5.com && echo "php目录已创建"
wget lftp://172.25.254.250/notes/project/software/lnmp/Discuz_X3.1_SC_UTF8.zip &> /dev/null
unzip Discuz_X3.1_SC_UTF8.zip &> /dev/null && echo "utf8已解压"
mv upload/*/usr/share/nginx/php-f5.com/
cat > /etc/sysconfig/spawn-fcgi << END
OPTIONS="-u nginx -g nginx -p 9000 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
END
service spawn-fcgi start && echo "fcgi已启动"
chkconfig spawn-fcgi on
netstat -tnlp |grep :9000
chkconfig nginx on
service nginx start && echo "nginx已启动"
cd /usr/share/nginx/php-f5.com/
chown nginx.nginx -R ./config/ ./data/ ./uc_server/ ./uc_client/
