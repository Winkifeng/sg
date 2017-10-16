#!/bin/bash
iptables -F
setenforce 0 && echo "防火墙已关闭"
rpm -ivh ftp://172.25.254.250/notes/project/UP200/UP200_nginx-mast
er/pkg/nginx-1.8.1-1.el7.ngx.x86_64.rpm &> /dev/null && echo "ngx压缩包已下载"
cat > /etc/nginx/nginx.conf << END
http {
include /etc/nginx/mime.types;
default_type application/octet-stream;
upstream php {
server 172.25.5.14:80 weight=1 max_fails=2 fail_timeout=1s;
server 172.25.5.15:80 weight=1 max_fails=2 fail_timeout=1s;
}
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
'$status $body_bytes_sent "$http_referer" '
'"$http_user_agent" "$http_x_forwarded_for"';
access_log /var/log/nginx/access.log main;
sendfile on;
tcp_nopush on;
keepalive_timeout 65;
gzip on;
include /etc/nginx/conf.d/*.conf;
}
END
cat > /etc/nginx/conf.d/default.conf << END
server {
listen 80;
server_name 127.0.0.1;
lotion ~ .*\.php$ {
proxy_pass http://php;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $remote_addr;
}
location / {
index index.php index.html index.htm;
proxy_pass http://php;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $remote_addr;
}
END
nginx -t
service nginx restart && echo "nginx已重启"
