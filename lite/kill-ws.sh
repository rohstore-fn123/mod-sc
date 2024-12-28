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

function send_log() {
    local user=$1
    local limit=$2
    local total=$3
    CHATID=$(cat /etc/funny/.chatid)
    KEY=$(cat /etc/funny/.keybot)
    TIME="10"
    TEXT="
<code>────────────────────</code>
<b>⚠️LIMIT QUOTA WebSocket⚠️</b>
<code>────────────────────</code>
<code>Username  : </code><code>$user</code>
<code>Limit     : </code><code>$limit</code>
<code>Total     : </code><code>$total</code>
<code>Status    : </code><code>Deleted</code>
<code>────────────────────</code>
"
    curl -s --max-time $TIME -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" "https://api.telegram.org/bot$KEY/sendMessage" >/dev/null
}

function human_readable() {
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

function check_quota() {
    local user=$1
    quota_file="/etc/xray/quota/ws/${user}"
    usage_file="/etc/xray/quota/ws/${user}_usage"
    log_file="/var/log/create/xray/ws/${user}"

    if [[ ! -f "$quota_file" ]]; then
        exp=$(grep -w "^### $user" "/etc/v2ray/config.json" | awk '{print $3}' | sort | uniq)
        if [[ -n "$exp" ]]; then
            sed -i "/### $user $exp/ {N;d}" /etc/v2ray/config.json
            systemctl daemon-reload
            systemctl restart v2ray
        fi

        echo -e "User tanpa file kuota ditemukan
        =================
        Username: $user
        Status: Deleted (Quota File Missing)
        =================
        " >> /etc/xray/.quota.logs

        send_log "$user" "File Kuota Tidak Ada" "N/A"

        rm -rf "$usage_file"
        rm -fr "$log_file"
        return
    fi

    if [[ -f "$quota_file" && -f "$usage_file" ]]; then
        quota_limit=$(cat "$quota_file")
        usage=$(cat "$usage_file")

        if [[ $usage -ge $quota_limit ]]; then
            exp=$(grep -w "^### $user" "/etc/v2ray/config.json" | awk '{print $3}' | sort | uniq)
            if [[ -n "$exp" ]]; then
                sed -i "/^### $user $exp/,/^###/d" /etc/v2ray/config.json
                systemctl daemon-reload
                systemctl restart v2ray
            fi

            readable_limit=$(human_readable "$quota_limit")
            readable_usage=$(human_readable "$usage")
            echo -e "Limit Quota Access
            =================
            Username: $user
            Limit Quota: $readable_limit
            Total Usage: $readable_usage
            Status: deleted
            =================
            " >> /etc/xray/.quota.logs

            send_log "$user" "$readable_limit" "$readable_usage"

            rm -rf "$quota_file"
            rm -rf "$usage_file"
            rm -fr "$log_file"
        fi
    fi
}

function process_quota() {
    users=$(grep '^###' /etc/v2ray/config.json | cut -d ' ' -f 2 | sort | uniq)

    for user in $users; do
        check_quota "$user"
    done
}

process_quota
echo -n > /var/log/v2ray/access.log