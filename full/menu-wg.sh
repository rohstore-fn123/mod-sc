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

# information
domain=$(cat /etc/xray/domain)
source /etc/wireguard/params
CLOUDFLAREKEY="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";

# Color
N="\033[0m"
R="\033[31m"
G="\033[32m"
B="\033[34m"
Y="\033[33m"
C="\033[36m"
M="\033[35m"
LR="\033[1;31m"
LG="\033[1;32m"
LB="\033[1;34m"
RB="\033[41;37m"
GB="\033[42;37m"
BB="\033[44;37m"

# Notification
OK="${G}[OK]${N}"
ERROR="${R}[ERROR]${N}"
INFO="${C}[+]${N}"

ok() {
  echo -e "${OK} ${G}$1${N}"
}

error() {
  echo -e "${ERROR} ${R}$1${N}"
}

info() {
  echo -e "${INFO} ${B}$1${N}"
}

newline() {
  echo -e ""
}

goback() {
  echo -e "Enter any keys to go back \c" 
	read back
	case $back in
	  *)
	    menu
      ;;
	esac
}

function create() {
	endpoint="${ip}:51820"

	clear
	newline
	echo -e "Add WireGuard User"
	echo -e "=================="
	echo -e " Username: \c"
	read user
	if grep -qw "^### Client ${user}\$" /etc/wireguard/wg0.conf; then
		newline
		error "$user already exist"
		newline
		goback
	fi
	echo -e " Duration Day: \c"
	read duration
	exp=$(date -d +${duration}days +%Y-%m-%d)
	expired=$(date -d "${exp}" +"%d %b %Y")

	for dot_ip in {2..254}; do
		dot_exists=$(grep -c "10.66.66.${dot_ip}" /etc/wireguard/wg0.conf)
		if [[ ${dot_exists} == '0' ]]; then
			break
		fi
	done
	if [[ ${dot_exists} == '1' ]]; then
		newline
		error "The subnet configured only supports 253 clients"
		newline
		goback
	fi

	client_ipv4="10.66.66.${dot_ip}"
	client_priv_key=$(wg genkey)
	client_pub_key=$(echo "${client_priv_key}" | wg pubkey)
	client_pre_shared_key=$(wg genpsk)

	echo -e "$user\t$exp" >> /etc/funny/.wireguard
	echo -e "[Interface]
PrivateKey = ${client_priv_key}
Address = ${client_ipv4}/32
DNS = 8.8.8.8,8.8.4.4

[Peer]
PublicKey = ${server_pub_key}
PresharedKey = ${client_pre_shared_key}
Endpoint = ${endpoint}
AllowedIPs = 0.0.0.0/0" >> /var/www/html/wireguard-${user}.conf
	echo -e "\n### Client ${user}
[Peer]
PublicKey = ${client_pub_key}
PresharedKey = ${client_pre_shared_key}
AllowedIPs = ${client_ipv4}/32" >> /etc/wireguard/wg0.conf
	systemctl daemon-reload
	systemctl restart wg-quick@wg0

	clear
	newline
	echo -e "WireGuard User Information"
	echo -e "=========================="
        echo -e " Domain\t: $domain /  bug.com.${domain}"
	echo -e " Username\t: $user"
	echo -e " Expired Date\t: $expired"
        echo -e "=========================="
        echo -e "Wireguard Detail"
	echo -e "Port Wireguard\t: 51820"
	echo -e "Private Key\t: ${client_priv_key}"
        echo -e "Publik Key\t: ${client_pub_key}"
	echo -e "=========================="
	echo -e "Link Config: http://${domain}/web/wireguard-${user}.conf"
        echo -e "=========================="
	newline
	goback
}

function warp() {
source /etc/wireguard/params
#ip=$(curl -sS curl -sS ipv4.icanhazip.com)
clear
echo -n "Enter your generated PRIVATE KEY: "
read PRIVATEKEY
echo -n "Enter your generated PUBLIC KEY: "
read PUBLICKEY

echo ""
echo "This will take 3-5 minutes, wait until the process is finished..."
echo ""

curl -d '{"key":"'$PUBLICKEY'", "install_id":"", "warp_enabled":true, "tos":"2019-11-17T00:00:00.000+01:00", "type":"Android", "locale":"en_GB"}' https://api.cloudflareclient.com/v0a737/reg | tee warp.json > /dev/null
sudo wg set wg0 peer '$CLOUDFLAREKEY' endpoint '$IPV4':51820 allowed-ips 172.16.0.0/24 > out.log 2> /dev/null
wg-quick down wg0 > out.log 2> /dev/null
wg-quick up wg0 > out.log 2> /dev/null

clear
clear
clear

warpd=$(cat warp.json | jq .)

clear
echo 'Wireguard has successfully installed in your VPS

Your PUBLICKEY is '$PUBLICKEY'
Your PRIVATEKEY is '$PRIVATEKEY'

_______________________

Your Client Config is:

[Interface]
Address = 172.16.0.2/12
DNS = 1.1.1.1
PrivateKey = '$PRIVATEKEY'

[Peer]
PublicKey = '$CLOUDFLAREKEY'
AllowedIPs = 0.0.0.0/0
Endpoint = engage.cloudflareclient.com:2408

_______________________
'$warpd'
_______________________
'
rm -fr warp.json
}

function delete() {
	clear
	newline
	echo -e "Delete WireGuard User"
	echo -e "====================="
	echo -e " Username: \c"
	read user
	if grep -qw "^### Client ${user}\$" /etc/wireguard/wg0.conf; then
		sed -i "/^### Client ${user}\$/,/^$/d" /etc/wireguard/wg0.conf
		if grep -q "### Client" /etc/wireguard/wg0.conf; then
			line=$(grep -n AllowedIPs /etc/wireguard/wg0.conf | tail -1 | awk -F: '{print $1}')
			head -${line} /etc/wireguard/wg0.conf > /tmp/wg0.conf
			mv /tmp/wg0.conf /etc/wireguard/wg0.conf
		else
			head -6 /etc/wireguard/wg0.conf > /tmp/wg0.conf
			mv /tmp/wg0.conf /etc/wireguard/wg0.conf
		fi
		rm -f /var/www/html/wireguard-${user}.conf
		sed -i "/\b$user\b/d" /etc/funny/.wireguard
		systemctl daemon-reload
		systemctl restart wg-quick@wg0
		newline
		ok "$user deleted successfully"
		newline 
		goback
	else
		newline
		error "$user does not exist"
		newline 
		goback
	fi
}

function extend() {
	clear
	newline
	echo -e "Extend WireGuard User"
	echo -e "====================="
	echo -e " Username: \c"
	read user
	if ! grep -qw "$user" /etc/funny/.wireguard; then
		newline
		error "$user does not exist"
		newline
		goback
	fi 
	echo -e " Duration Day: \c"
	read extend

	exp_old=$(cat /etc/funny/.wireguard | grep -w $user | awk '{print $2}')
	diff=$((($(date -d "${exp_old}" +%s)-$(date +%s))/(86400)))
	duration=$(expr $diff + $extend + 1)
	exp_new=$(date -d +${duration}days +%Y-%m-%d)
	exp=$(date -d "${exp_new}" +"%d %b %Y")

	sed -i "/\b$user\b/d" /etc/funny/.wireguard
	echo -e "$user\t$exp_new" >> /etc/funny/.wireguard

	clear
	newline
	echo -e "WireGuard User Information"
	echo -e "=========================="
	echo -e " Username\t: $user"
	echo -e " Expired Date\t: $exp"
	newline 
	goback
}

function list() {
	clear
	newline
	echo -e "==========================="
	echo -e "Username          Exp. Date"
	echo -e "==========================="
	while read expired
	do
		user=$(echo $expired | awk '{print $1}')
		exp=$(echo $expired | awk '{print $2}')
		exp_date=$(date -d"${exp}" "+%d %b %Y")
		printf "%-17s %2s\n" "$user" "$exp_date"
	done < /etc/funny/.wireguard
	total=$(wc -l /etc/funny/.wireguard | awk '{print $1}')
	echo -e "==========================="
	echo -e "Total Accounts: $total     "
	echo -e "==========================="
	newline
	goback
}

function show() {
	clear
	newline
	echo -e "WireGuard Configuration"
	echo -e "======================="
	echo -e " Username\t: \c"
	read user
	if grep -qw "^### Client ${user}\$" /etc/wireguard/wg0.conf; then
		exp=$(cat /etc/funny/.wireguard | grep -w "$user" | awk '{print $2}')
		exp_date=$(date -d"${exp}" "+%d %b %Y")
		echo -e " Expired\t: $exp_date"
		newline
		qrencode -t ansiutf8 -l L < /var/www/html/wireguard-${user}.conf
		newline
		echo -e "Configuration"
		echo -e "============="
		newline
		cat /var/www/html/wireguard-${user}.conf
		newline 
		goback
	else
		newline
		error "$user does not exist"
		newline
		goback
	fi
}

function main() {
clear
newline
echo -e "=============================="
echo -e "        WireGuard Menu        "
echo -e "=============================="
newline
echo -e "  [1] Add WireGuard User"
echo -e "  [2] Delete WireGuard User"
echo -e "  [3] Extend WireGuard User"
echo -e "  [4] WireGuard User List"
echo -e "  [5] WireGuard Configuration"
echo -e "  [6] Add Wireguard Warp Cloudflare"
echo -e "  [7] Back"
newline
echo -e "=============================="
echo -e " Select Menu: \c"
read menu
case $menu in
1)
	create
	goback
	;;
2)
	delete 
	goback
	;;
3)
	extend 
	goback
	;;
4)
	list 
	goback
	;;
5)
	show 
	goback
	;;
6)
	warp
	goback
	;;
7)
	menu
	;;
*) 
	clear 
	newline
	error "Invalid option"
	newline
	goback
	;;
esac
}

main

