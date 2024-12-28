#!/bin/bash

[[ -e $(which curl) ]] && grep -q "1.1.1.1" /etc/resolv.conf || { 
    echo "nameserver 1.1.1.1" | cat - /etc/resolv.conf >> /etc/resolv.conf.tmp && mv /etc/resolv.conf.tmp /etc/resolv.conf
}


    # Konfigurasi URL izin
    PERMISSION_URL="https://permision.rerechanstore.eu.org/izin.txt"
    LOCAL_IP=$(curl -s ifconfig.me) # Mendapatkan IP lokal

    # Fungsi menghitung sisa waktu
    calculate_remaining_days() {
        local today=$(date +%s)
        local expired_date=$(date -d "$1" +%s 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "Tanggal kadaluwarsa tidak valid."
            exit 1
        fi
        echo $(( (expired_date - today) / 86400 ))
    }

    # Unduh izin dan validasi
    clear
    PERMISSION_DATA=$(curl -s "$PERMISSION_URL" || { echo "Gagal mengunduh izin."; exit 1; })

    # Mencocokkan data berdasarkan IP lokal
    MATCH=$(echo "$PERMISSION_DATA" | grep "###" | grep "$LOCAL_IP")
    if [ -z "$MATCH" ]; then
        echo "Your IP doesn’t have on database"
        exit 1
    fi

    # Ekstraksi data dari baris yang cocok
    USERNAME=$(echo "$MATCH" | awk '{print $2}')
    PERMISSION_IP=$(echo "$MATCH" | awk '{print $3}')
    EXPIRED_DATE=$(echo "$MATCH" | awk '{print $4}')

    # Validasi masa aktif
    REMAINING_DAYS=$(calculate_remaining_days "$EXPIRED_DATE")
    if [ "$REMAINING_DAYS" -lt 0 ]; then
        echo "Izin telah kadaluwarsa."
        exit 1
    fi

    # Output informasi izin
    output() {
        echo "Username: $USERNAME"
        echo "IPv4: $PERMISSION_IP"
        echo "Expired: $EXPIRED_DATE ( $REMAINING_DAYS Days )"
    }

    output

ungu="\033[0;35m"
Xark="\033[0m"
BlueCyan="\033[5;36m"
hosting="https://raw.githubusercontent.com/UmVyZWNoYW4wMgo/Zm4K/refs/heads/main"

# Mengisi Data
clear
echo -e "${BlueCyan} ——————————————————————————————————— ${Xark} "
echo -e "${ungu}            FN PROJECT      ${Xark} "
echo -e "${BlueCyan} ——————————————————————————————————— ${Xark} "

while true; do
    read -p "Input Domain: " domain
    read -p "Input Email : " email
    read -p "Input Type IP VPS (4/6/dual): " ips
    # Cek jika input kosong
    if [[ -z "$domain" ]]; then
        echo "Domain tidak boleh kosong. Silakan coba lagi."
        continue
    fi

    # Cek jika input mengandung spasi
    if [[ "$domain" =~ [[:space:]] ]]; then
        echo "Domain tidak boleh mengandung spasi. Silakan coba lagi."
        continue
    fi

    # Jika lolos validasi
    echo "Domain valid: $domain"
    break
done

# Menyimpan Domain
mkdir -p /etc/xray
echo -e "${domain}" > /etc/xray/domain
curl -sS ipinfo.io/ip > /etc/.ip

# Menyimpan Email
mkdir -p /etc/funny
echo -e "${email}" > /etc/funny/.email

# Menyiman Tipe IP
echo -e "${ips}" > /root/.ips

# Package Sementara
apt install wget curl -y
apt install zip unzip -y
apt install vnstat -y
apt install lsof -y

# Installasi Package Full
wget --no-check-certificate ${hosting}/installer/package.sh >> /dev/null 2>&1
chmod +x package.sh
./package.sh
cd
rm -f /root/package.sh

# Copy Filer
cd /usr/bin
wget --no-check-certificate ${hosting}/menu/full.zip >> /dev/null 2>&1
chmod +x full.zip
unzip full.zip
chmod +x *
rm -f full.zip
cd

# Installasi SSH WebSocket
wget --no-check-certificate ${hosting}/installer/ssh.sh >> /dev/null 2>&1
chmod +x ssh.sh
./ssh.sh
cd
rm -f /root/ssh.sh

# Installasi X-Ray
wget --no-check-certificate ${hosting}/installer/xray.sh >> /dev/null 2>&1
chmod +x xray.sh
./xray.sh
cd
rm -f /root/xray.sh

# Installasi V2Ray
wget --no-check-certificate ${hosting}/installer/v2ray.sh >> /dev/null 2>&1
chmod +x v2ray.sh
./v2ray.sh
cd
rm -f /root/v2ray.sh

# Menginstall WebSite Restore
wget --no-check-certificate -O /root/website.sh "${hosting}/website/install.sh" >> /dev/null 2>&1
chmod +x /root/website.sh
cd
./website.sh

# Installasi Web Server & Setup Certificate
wget --no-check-certificate ${hosting}/installer/diamond.sh >> /dev/null 2>&1
chmod +x diamond.sh
./diamond.sh
cd
rm -f /root/diamond.sh

# Installasi OpenVPN
wget --no-check-certificate ${hosting}/installer/vpn.sh >> /dev/null 2>&1
chmod +x vpn.sh
./vpn.sh
cd
rm -f /root/vpn.sh

# Installasi SlowDNS
wget --no-check-certificate ${hosting}/installer/slowdns.sh >> /dev/null 2>&1
chmod +x slowdns.sh
./slowdns.sh
cd
rm -f /root/slowdns.sh

# Installasi L2TP
wget --no-check-certificate ${hosting}/installer/l2tp.sh >> /dev/null 2>&1
chmod +x l2tp.sh
./l2tp.sh
cd
rm -f /root/l2tp.sh

# Installasi Wireguard
wget --no-check-certificate ${hosting}/installer/wg.sh >> /dev/null 2>&1
chmod +x wg.sh
./wg.sh
cd
rm -f /root/wg.sh

# Installasi NoobzVPN'S
cd /root
wget --no-check-certificate ${hosting}/installer/noobz.sh >> /dev/null 2>&1
chmod +x noobz.sh
./noobz.sh
cd
rm -f /root/noobz.sh

# Installasi UDP Custom & UDP Request
wget --no-check-certificate ${hosting}/installer/udp.sh >> /dev/null 2>&1
chmod +x udp.sh
./udp.sh
rm -f /root/udp.sh
wget --no-check-certificate ${hosting}/installer/request.sh >> /dev/null 2>&1
chmod +x request.sh
./request.sh
rm -f /root/request.sh

# Restart
systemctl daemon-reload
systemctl restart fn-ohp
systemctl restart noobzvpns

# Installasi Selesai
echo -e "1.23" > /etc/funny/version
OUTPUT="
DETAIL INSTALL SCRIPT 1.23
=========================
IP: $(curl ifconfig.me)
Domain: $domain
Email Own: $email
Type IP: $ips
Type Script: Full
=========================
@fn_project Autoscript
"
CHATID="6389176425"
KEY="6981433170:AAH8q0tC2c06dR5mC0lmH3JS-VaXH3g2DL4"
TIME="10"
URL="https://api.telegram.org/bot$KEY/sendMessage"
curl -s --max-time $TIME --data-urlencode "chat_id=$CHATID" --data-urlencode "text=$OUTPUT" $URL >/dev/null 2>&1

# Status Installasi
clear
echo ""
echo -e "\033[96m_______________________________\033[0m"
echo -e "\033[92m         INSTALL SUCCES\033[0m"
echo -e "\033[96m_______________________________\033[0m"
