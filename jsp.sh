#!/bin/bash
iptables -F
setenfouce 0 && echo "防火墙已关闭"
yum -y install lftp &> /dev/null && echo "lftp已安装"
lftp 172.25.254.250:/notes/project/UP200/UP200_tomcat-master
mirror pkg/
exit

cd pkg/
tar -xf jdk-7u15-linux-x64.tar.gz -C /opt/ && echo "解压已完成"
mv /opt/jdk1.7.0_15/ /opt/java
mkdir /usr/local/tomcat && echo "tomcat目录已创建"
tar -xf apache-tomcat-8.0.24.tar.gz -C /usr/lo
cal/tomcat && echo "解压已完成"
groupadd -g 888 tomcat && echo "tomcat组已创建"
useradd -g 888 -u 888 tomcat -s /sbin/nologin && echo "tomcat用户已创建"
cd /usr/local/tomcat/apache-tomcat-8.0.24/bin/
tar -xf commons-daemon-native.tar.gz && echo "解压完成"
cd commons-daemon-1.0.15-native-src/unix/
yum -y install gcc &> /dev/null && echo "gcc已安装"
./configure --with-java=/opt/java &> /dev/null && echo "编译完成"
make &> /dev/null && echo "make完成"
cp -a jsvc /usr/local/tomcat/apache-tomcat-8.0.24/bin/
cd /usr/local/tomcat/apache-tomcat-8.0.24/bin/
cp daemon.sh /etc/init.d/tomcat
cat > /etc/init.d/tomcat << END
CATALINA_HOME=/usr/local/tomcat/apache-tomcat-8.0.24
CATALINA_BASE=/usr/local/tomcat/apache-tomcat-8.0.24
JAVA_HOME=/opt/java/
END
chmod +x /etc/init.d/tomcat
chkconfig --add tomcat
chown tomcat.tomcat -R /usr/local/tomcat/apache-tomcat-8.0.24/
service tomcat start && echo "tomcat已启动"
ps aux |grep tomcat
netstat -tnlp |grep :80
cat > /usr/local/tomcat/apache-tomcat-8.0.24/conf/server.xml << END
<Host name="www.jsp-f5.com" appBase="jsp-f5.com"
unpackWARs="true" autoDeploy="true">
<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
prefix="jsp-f5.com_access_log" suffix=".txt"
pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
END
mkdir -p /usr/local/tomcat/apache-tomcat-8.0.24/jsp-f5.com/ROOT/ && echo "jsp目录已创建"
wget ftp://172.25.254.250/notes/project/software/tomcat/ejforum-2.3.zip &> /dev/null && echo "压缩包下载完成"
mv ejforum-2.3/ejforum/ /usr/local/tomcat/apache-tomcat-8.0.24/jsp-f5.com/ROOT/
mv ejforum-2.3.zip /usr/local/tomcat/apache-tomcat-8.0.24/jsp-f5.com/ROOT/
cd /usr/local/tomcat/apache-tomcat-8.0.24/jsp-f5.com/ROOT/
unzip ejforum-2.3.zip && echo "解压完成"
ls
mv * /usr/local/tomcat/apache-tomcat-8.0.24/jsp-f5.com/ROOT/
cat > /usr/local/tomcat/apache-tomcat-8.0.24/conf/server.xml << END
<Context path="" docBase="/usr/local/tomcat/apache-tomcat-8.0.24/jsp-f5.com/ROOT" />
END
cd ~/pkg/
tar xf mysql-connector-java-5.1.36.tar.gz -C /tmp/
cp /tmp/mysql-connector-java-5.1.36/mysql-connector-java-5.1.36-bin.jar /usr/local/tomcat/apache-tomcat-8.0.24/lib/
cat > usr/local/tomcat/apache-tomcat-8.0.24/jsp-f5.com/ROOT/WEB-INF/conf/config.xml << END
<database maxActive="10" maxIdle="10" minIdle="2" maxWait="10000"
username="runjsp" password="123456"
driverClassName="com.mysql.jdbc.Driver"
url="jdbc:mysql://172.25.254.221:3306/jsp?characterEncoding=gbk&amp;autoReconnect=true&
amp;autoReconnectForPools=true&amp;zeroDateTimeBehavior=convertToNull"
sqlAdapter="sql.MysqlAdapter"/>
END
wget ftp://172.25.254.250/notes/project/software/tomcat/ejforum-2.3.zip &> /dev/null && echo "压缩包下载完成"
unzip ejforum-2.3.zip -d /tmp/ && echo "解压完成"
cd /tmp/ejforum-2.3/install/script/
yum -y install mariadb &> /dev/null && echo "mariadb安装完成"
mysql -urunjsp -p123456 jsp -h172.25.254.221 < easyjforum_mysql.sql
chown tomcat.tomcat -R /usr/local/tomcat/apache-tomcat-8.0.24/
service tomcat stop
service tomcat start

