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
clear

# Fungsi untuk mengirim log ke Telegram
function send_log() {
    CHATID=$(cat /etc/funny/.chatid)
    KEY=$(cat /etc/funny/.keybot)
    URL="https://api.telegram.org/bot${KEY}/sendMessage"

    TEXT="
<code>────────────────────</code>
<b> NOTIF QUOTA SPLIT HTTP HABIS</b>
<code>────────────────────</code>
<code>Username  : </code><code>${user}</code>
<code>Usage     : </code><code>${total_usage}</code>
<code>Limit     : </code><code>${total_limit}</code>
<code>Status    : </code><code>Deleted</code>
<code>────────────────────</code>
"
    curl -s -X POST "$URL" -d "chat_id=${CHATID}&text=${TEXT}&parse_mode=html" >/dev/null
}

# Fungsi untuk mengonversi byte ke format manusiawi
function con() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ $bytes -lt 1048576 ]]; then
        printf "%.2f KB\n" "$(bc -l <<< "scale=2; $bytes/1024")"
    elif [[ $bytes -lt 1073741824 ]]; then
        printf "%.2f MB\n" "$(bc -l <<< "scale=2; $bytes/1048576")"
    elif [[ $bytes -lt 1099511627776 ]]; then
        printf "%.2f GB\n" "$(bc -l <<< "scale=2; $bytes/1073741824")"
    elif [[ $bytes -lt 1125899906842624 ]]; then
        printf "%.2f TB\n" "$(bc -l <<< "scale=2; $bytes/1099511627776")"
    else
        printf "%.2f PB\n" "$(bc -l <<< "scale=2; $bytes/1125899906842624")"
    fi
}

# Fungsi untuk memeriksa penggunaan split
function ceksplit() {
    users=$(grep '^###' /etc/xray/json/split.json | cut -d ' ' -f 2 | sort | uniq)

    for user in $users; do
        # Ambil statistik penggunaan dari Xray API
        usage_data=$(xray api statsquery --server=127.0.0.1:10082 | grep -C 2 "$user" | grep value | awk '{print $2}' | sed 's/,//g; s/"//g')
        inb=$(echo "$usage_data" | sed -n 1p)
        outb=$(echo "$usage_data" | sed -n 2p)

        # Validasi data inb dan outb
        if [[ -z "$inb" || -z "$outb" ]]; then
            echo "Data usage for user $user is incomplete. Skipping."
            continue
        fi

        quota_used=$((inb + outb))
        usage_file="/etc/xray/quota/split/${user}_usage"
        quota_file="/etc/xray/quota/split/${user}"

        if [ -f "$usage_file" ]; then
            previous_usage=$(cat "$usage_file")
            quota_used=$((quota_used + previous_usage))
        fi
        echo "$quota_used" > "$usage_file"

        quota_limit=$(cat "$quota_file")
        if [[ "$quota_used" -gt "$quota_limit" ]]; then
            exp=$(grep -w "^### $user" "/etc/xray/json/split.json" | cut -d ' ' -f 3 | sort | uniq)
            sed -i "/### $user $exp/ {N;d}" /etc/xray/json/split.json
            total_usage=$(con "$quota_used")
            total_limit=$(con "$quota_limit")
            send_log
            rm -f "$usage_file" "$quota_file"
            echo "User $user reached quota limit and has been locked."
        fi

        # Reset statistik
        xray api stats --server=127.0.0.1:10082 -name "user>>>${user}>>>traffic>>>downlink" -reset >/dev/null 2>&1
        xray api stats --server=127.0.0.1:10082 -name "user>>>${user}>>>traffic>>>uplink" -reset >/dev/null 2>&1
    done
}

# Fungsi utama untuk memonitor split secara terus-menerus
function split() {
    while true; do
        sleep 30
        ceksplit
    done
}

# Eksekusi fungsi utama
split