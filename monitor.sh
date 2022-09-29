#!bin/bash

NC='\033[0m'
Green='\033[1;32m'
Yellow='\033[1;33m'
Purple='\033[1;95m'
Red='\033[1;91m'

echo "Installing Netdata"

curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --no-updates --stable-channel --disable-telemetry

echo "Installing Mysql Exporter"

curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest   | grep browser_download_url   | grep linux-amd64 | cut -d '"' -f 4   | wget -qi -

tar xvf mysqld_exporter*.tar.gz

sudo chmod +x mysqld_exporter-*.linux-amd64/mysqld_exporter

sudo mv mysqld_exporter-*.linux-amd64/mysqld_exporter /usr/local/bin/

echo "Installing Exporter Exporter"

curl -s https://api.github.com/repos/QubitProducts/exporter_exporter/releases/latest   | grep browser_download_url | grep linux-amd64 |  cut -d '"' -f 4 | wget -qi -

tar xvf exporter_exporter*.tar.gz

sudo chmod +x exporter_exporter-*.linux-amd64/exporter_exporter

sudo mv exporter_exporter-*.linux-amd64/exporter_exporter /usr/local/bin/

echo "Installing Statsd exporter"

curl -s https://api.github.com/repos/prometheus/statsd_exporter/releases/latest   | grep browser_download_url | grep linux-amd64 |  cut -d '"' -f 4 | wget -qi -

tar xvf statsd_exporter*.tar.gz

sudo chmod +x statsd_exporter-*.linux-amd64/statsd_exporter

sudo mv statsd_exporter-*.linux-amd64/statsd_exporter /usr/local/bin/

echo "Installing all the config files"

sudo mkdir -p /etc/exporter_exporter.d

sudo mkdir -p /etc/statsd_exporter

sudo curl -o /etc/exporter_exporter.d/expexp.yaml https://raw.githubusercontent.com/athul/monitoring-confs/main/expexp.yaml

sudo curl -o /etc/.mysqld_exporter.cnf https://raw.githubusercontent.com/athul/monitoring-confs/main/mysql_exporter.cnf

sudo curl -o /etc/statsd_exporter/statsd.conf https://raw.githubusercontent.com/athul/monitoring-confs/main/statsd.conf

sudo curl -o /etc/systemd/system/mysql_exporter.service https://raw.githubusercontent.com/athul/monitoring-confs/main/mysql_exporter.service

sudo curl -o /etc/systemd/system/exporter_exporter.service https://raw.githubusercontent.com/athul/monitoring-confs/main/exporter_exporter.service

sudo curl -o /etc/systemd/system/statsd_exporter.service https://raw.githubusercontent.com/athul/monitoring-confs/main/statsd_exporter.service

echo -e "${Purple}You'll need to configure Gunicorn for Statsd, Mysql config for Mysqld exporter and Nginx${NC}"
echo -e "\n\n${Red}----Supervisor----${NC}\n\n"
echo -e "${Green}Add :${Yellow} --statsd-host=localhost:9125 --statsd-prefix=\"frappe-bench-web\"${NC} ${Green}to supervisord.conf file for Gunicorn \nrestart supervisor with${NC} ${Yellow}sudo supervisorctl reload${NC}"
echo -e "\n\n${Red}----Nginx----${NC}\n\n"
echo -e "${Purple}Add the following to the start of the Nginx(/etc/nginx/conf.d/frappe-bench.conf) Config${NC}\n"
echo -e "${Yellow} upstream monitor {\n\tserver 127.0.0.1:9999;\n\tkeepalive 64;\n}${NC}\n\n"
echo -e "${Green}Add the following before the${NC} ${Purple}@webserver location${NC}\n\n"
echo -e "${Yellow}location ~ /mon/(?<ndpath>.*) {\n\tauth_basic \"Restricted Content\";\n\tauth_basic_user_file /etc/nginx/.htpasswd;\n\tproxy_redirect $host /mon/;\n\tproxy_set_header Host $host;\n\tproxy_set_header X-Forwarded-Host $host;\n\tproxy_set_header X-Forwarded-Server $host;\n\tproxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\tproxy_http_version 1.1;\n\tproxy_pass_request_headers on;\n\tproxy_set_header Connection \"keep-alive\";\n\tproxy_store off;\n\tproxy_pass http://monitor/mon/$ndpath$is_args$args;\n\t}${NC}"
echo -e "\n${Green} Restart Nginx${NC}"
echo -e "\n\n${Red}----Systemctl----${NC}\n\n"
echo -e "${Yellow}sudo systemctl enable/start {service_name}${NC}\n"


