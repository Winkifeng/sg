#!/bin/bash
iptables -F
setenforce 0 && echo "防火墙已关闭"
rpm -ivh ftp://172.25.254.250/notes/project/UP200/UP200_nginx-mast
er/pkg/nginx-1.8.1-1.el7.ngx.x86_64.rpm &> /dev/null && echo "ngx压缩包已下载"
cat > /etc/nginx/nginx.conf << END
service nginx restart && echo "nginx已重启"
tream static-jsp {
server 172.25.5.16:80 weight=1 max_fails=2 fail_timeout=1s;
server 172.25.5.17:80 weight=1 max_fails=2 fail_timeout=1s;
}
upstream tomcat {
server 172.25.5.16:8080 weight=1 max_fails=2 fail_timeout=1s;
server 172.25.5.17:8080 weight=1 max_fails=2 fail_timeout=1s;
}
END

cat > /etc/nginx/conf.d/default.conf << END
server {
listen 80;
server_name 127.0.0.1;
location ~ .*\.jsp$ {
proxy_pass http://tomcat;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $remote_addr;
}
location / {
index index.jsp index.html index.htm;
proxy_pass http://static-jsp;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $remote_addr;
}
location ~ ^/forum-[0-9]-[0-9]-[0-9]\.html$ {
proxy_pass http://tomcat;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $remote_addr;
}

}
END

service nginx restart && echo "nginx已重启"
