#!/bin/bash

cat > /serverb.sh << EOF
#!/bin/bash
iptables -F
setenforce 0

rpm -ivh ftp://172.25.254.250/notes/project/UP200/UP200_nginx-master/pkg/nginx-1.8.0-1.el7.ngx.x86_64.rpm
mkdir -p /usr/share/nginx/ccd/tom

cat > /etc/nginx/conf.d/default.conf << EOT
server {
    listen       80;
    server_name  localhost;

    location / {
        proxy_pass http://172.25.6.12;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}

EOT

cat > /etc/nginx/nginx.conf << EOT
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\\\$remote_addr - \\\$remote_user [\$time_local] "\\\$request" '
                      '\\\$status \\\$body_bytes_sent "\\\$http_referer" '
                      '"\\\$http_user_agent" "\\\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;

    keepalive_timeout  65;
    proxy_temp_path /usr/share/nginx/proxy_temp_dir 1 2;
    proxy_cache_path /usr/share/nginx/proxy_cache_dir levels=1:2 keys_zone=cache_web:50m inactive=1d max_size=30g;

    upstream apache_pool {
    server 172.25.6.12 weight=2;
    server 172.25.6.13 weight=2;
    }

    include /etc/nginx/conf.d/*.conf;
}

EOT

mkdir -p /usr/share/nginx/proxy_temp_dir /usr/share/nginx/proxy_cache_dir
chown nginx /usr/share/nginx/proxy_temp_dir/ /usr/share/nginx/proxy_cache_dir/



cat > /etc/nginx/conf.d/www.ccd.com.conf << EOT
 server {
 	listen 80;
 	server_name *.ccd.com;
 	root /usr/share/nginx/ccd;
 	index index.html index.htm;
 	if ( \\\$http_host ~* ^www\.ccd\.com$ ) {    
 		break;
 		}
 	if ( \\\$http_host ~* ^(.*)\.ccd\.com$ ) {    
 		set \\\$domain \\\$1;	
 		rewrite /.* /\\\$domain/index.html break;
 	}
 }
EOT

cat > /etc/nginx/conf.d/default.conf << EOT
server {
    listen       80;
    server_name  www.proxy.com;
location / {
proxy_pass http://apache_pool;
proxy_set_header Host \\\$host;
proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
proxy_set_header X-Real-IP \\\$remote_addr;
proxy_redirect off;
client_max_body_size 10m;
client_body_buffer_size 128k;
proxy_connect_timeout 90;
proxy_send_timeout 90;
proxy_read_timeout 90;
proxy_cache cache_web;
proxy_cache_valid 200 302 12h;
proxy_cache_valid 301 1d;
proxy_cache_valid any 1h;
proxy_buffer_size 4k;
proxy_buffers 4 32k;
proxy_busy_buffers_size 64k;
proxy_temp_file_write_size 64k;
}
}
EOT

cd /usr/share/nginx/ccd/
echo tom > tom/index.html
ulimit -HSn 65535
nginx -t

systemctl restart nginx
systemctl enable nginx
EOF

chmod +x /serverb.sh
rsync -a /serverb.sh 172.25.6.11:/
ssh root@172.25.6.11 "bash -x /serverb.sh"

cat > /serverc.sh << EOF
#!/bin/bash
iptables -F
setenforce 0

yum -y install httpd &> /dev/null && echo "httpd安装成功"
echo serverc1-webserver > /var/www/html/index.html
systemctl restart httpd
EOF

chmod +x /serverc.sh
rsync -a /serverc.sh 172.25.6.12:/
ssh root@172.25.6.12 "bash -x /serverc.sh"

cat > /serverd.sh << EOF
#!/bin/bash
iptables -F
setenforce 0
yum -y install httpd &> /dev/null && echo "httpd安装成功"
echo serverd1-webserver > /var/www/html/index.html
systemctl restart httpd
systemctl enable httpd
EOF

chmod +x /serverd.sh
rsync -a /serverd.sh 172.25.6.13:/
ssh root@172.25.6.13 "bash -x /serverd.sh"
