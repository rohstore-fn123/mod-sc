#!/bin/bash
hosting="https://raw.githubusercontent.com/UmVyZWNoYW4wMgo/Zm4K/refs/heads/main"
curl https://rclone.org/install.sh | bash
printf "q\n" | rclone config
#wget -O /root/.config/rclone/rclone.conf "${hosting}/config/rclone.conf"
wget -O /root/.config/rclone/rclone.conf "https://raw.githubusercontent.com/rohstore-fn123/AutoScriptVPN-AIO/Beginner/rclone.conf"
git clone https://github.com/rohstore-fn123/wondershaper.git
cd wondershaper
make install
rm -rf wondershaper
echo > /home/limit
apt install msmtp-mta ca-certificates bsd-mailx -y
cat<<EOF>>/etc/msmtprc
defaults
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account default
host smtp.gmail.com
port 587
auth on
user revolution.become.true@gmail.com
from revolution.become.true@gmail.com
password rmjydsqnwhehcanj  
logfile ~/.msmtp.log
EOF
sudo iptables -A INPUT -p tcp --dport 587 -j ACCEPT
sudo ufw allow 587/tcp
chown -R www-data:www-data /etc/msmtprc
cd /usr/bin
rm -f /root/set-br.sh