#!/usr/bin/env bash

DISPLAY_NAME=${DISPLAY_NAME:-'Argo_xray_'}

# 定义 UUID 及 伪装路径,请自行修改.(注意:伪装路径以 / 符号开始,为避免不必要的麻烦,请不要使用特殊符号.)
UUID=${UUID:-'966b4678-366c-40a6-8526-f8f8b81448a6'}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VMESS_WARP_WSPATH=${VMESS_WARP_WSPATH:-'/vmess_warp'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
VLESS_WARP_WSPATH=${VLESS_WARP_WSPATH:-'/vless_warp'}
TROJAN_WSPATH=${TROJAN_WSPATH:-'/trojan'}
TROJAN_WARP_WSPATH=${TROJAN_WARP_WSPATH:-'/trojan_warp'}
SS_WSPATH=${SS_WSPATH:-'/shadowsocks'}
SS_WARP_WSPATH=${SS_WARP_WSPATH:-'/shadowsocks_warp'}

VAR_NAMES=("UUID" "VMESS_WSPATH" "VMESS_WARP_WSPATH" "VLESS_WSPATH" "VLESS_WARP_WSPATH" "TROJAN_WSPATH" "TROJAN_WARP_WSPATH" "SS_WSPATH" "SS_WARP_WSPATH")

# Function to perform variable substitution in a text file
perform_variable_substitution() {
	local text_file="$1"  # Text file to be processed
	shift  # Shift the arguments to remove the text_file argument
	local var_names=("$@")  # Array of variable names

	# Iterate over each variable name in the array
	for var_name in "${var_names[@]}"; do
		# Get the value of the variable
		local var_value="${!var_name}"
		local escaped_value="${var_value//\//\\/}"  # Escape forward slashes

		# Replace the placeholder with the variable value in the text file
		sed -i "s/#$var_name#/$escaped_value/g" "$text_file"
	done
}

perform_substitutions() {
	[ -f "$2" ] && rm "$2"
	cp "$1" "$2"
	perform_variable_substitution "$2" "${VAR_NAMES[@]}"
}

perform_substitutions template_config.json config.json
perform_substitutions template_nginx.conf /etc/nginx/nginx.conf

# 配置并启动SSH服务器
KEYS_FILE="/root/.ssh/authorized_keys"
mkdir -p /root/.ssh
echo $SSH_PUBKEY > $KEYS_FILE
echo $SSH_PUBKEY2 >> $KEYS_FILE
echo $SSH_PUBKEY3 >> $KEYS_FILE
echo $SSH_PUBKEY4 >> $KEYS_FILE
chmod 644 $KEYS_FILE
/etc/init.d/ssh restart

# 设置 nginx 伪装站
rm -rf /usr/share/nginx/*
unzip -o "./mikutap.zip" -d /usr/share/nginx/html

# 伪装 xray 执行文件
RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
[ -f "exec.txt" ] && RELEASE_RANDOMNESS=$(<exec.txt tr -d '\n') || echo -n $RELEASE_RANDOMNESS > exec.txt
mv xray $RELEASE_RANDOMNESS
[ -f "geoip.dat" ] && rm "geoip.dat"
[ -f "geosite.dat" ] && rm "geosite.dat"
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
cat config.json | base64 > config
rm -f config.json
