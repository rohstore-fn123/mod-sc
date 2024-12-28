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

hosting="https://raw.githubusercontent.com/UmVyZWNoYW4wMgo/Zm4K/refs/heads/main"

clear

# Package
apt update
apt install curl -y
apt install dos2unix -y

# Repository
rm -fr /root/udp*
mkdir -p /root/udp-custom
cd /root/udp-custom

# Copy Code & Create Config
wget --no-check-certificate -O udp-custom-linux-amd64 ${hosting}/udp/udp-custom-linux-amd64

cat > /root/udp-custom/config.json <<-JSON
{
  "listen": ":36711",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
JSON

# Permision
cd /root/udp-custom
chmod +x udp-custom-linux-amd64
chmod +x config.json

# Membuat Service
cd /etc/systemd/system
cat > udp-custom.service <<-SERV
[Unit]
Description=Udp Custom By FN Project

[Service]
User=root
Type=simple
ExecStart=/root/udp-custom/udp-custom-linux-amd64
WorkingDirectory=/root/udp-custom/
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
SERV

# Menyalakan Service
systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

# Filer
rm -f /root/udp.sh
