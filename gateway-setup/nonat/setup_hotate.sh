#!/bin/sh
# base: none
# This script was written by chun37 instead of myazakky.
#
# 使い方:
#   curl -L https://raw.githubusercontent.com/geek-space-hq/gsnet-scripts/master/gateway-setup/nat/setup_hotate.sh > /tmp/setup_tinc.sh; sudo sh /tmp/setup_tinc.sh <ノード名> <IPアドレス>
#   または
#   curl -L https://raw.githubusercontent.com/geek-space-hq/gsnet-scripts/master/gateway-setup/nat/setup_hotate.sh > /tmp/setup_tinc.sh; sudo sh /tmp/setup_tinc.sh <ノード名> <IPアドレス> <GSNetのセグメントに参加させるインターフェイス>
#

if test -d /etc/tinc/gsnet; then
  printf 'エラー: /etc/tinc/gsnet は既に存在します\n'
  printf 'セットアップを中止します\n'
  exit 1
fi

if echo "${1}" | grep -v '^[0-9a-z_][0-9a-z_]*$'; then
  printf 'エラー: ノード名に使える文字は [a-z0-9_] のみです\n'
  printf 'セットアップを中止します\n'
  exit 1
fi

NODE_NAME="${1}"
IP_ADDRESS="${2}"
ETHERNET_INTERFACE="${3}"
SERVER_NODE_NAME="hotate"

printf 'NODE_NAME: %s\n' "${NODE_NAME}"
printf 'IP_ADDRESS: %s\n' "${IP_ADDRESS}"
printf 'ETHERNET_INTERFACE: %s\n' "${ETHERNET_INTERFACE}"

# tincのインストール
apt-get update
apt-get install -y tinc

# 設定用ディレクトリの作成
mkdir /etc/tinc/gsnet
mkdir /etc/tinc/gsnet/hosts

# tinc.conf の作成
sed -e 's/{NODE_NAME}/'"${NODE_NAME}"'/' -e 's/{SERVER_NODE_NAME}/'"${SERVER_NODE_NAME}"'/' > /etc/tinc/gsnet/tinc.conf <<'EOF'
Name = {NODE_NAME}
Mode = switch
Device = /dev/net/tun
ConnectTo = {SERVER_NODE_NAME}
EOF

# tinc-up スクリプトの作成
# このシェルスクリプトはVPNセッションの開始時に実行される
if [ -n "${ETHERNET_INTERFACE}" == "" ]; then
  sed -e 's/{IP_ADDRESS}/'"${IP_ADDRESS}"'/' -e 's/{ETHERNET_INTERFACE}/'"${ETHERNET_INTERFACE}"'/' > /etc/tinc/gsnet/tinc-up <<'EOF'
#!/bin/sh
ip link add br0 type bridge
ip link set br0 up
ip link set $INTERFACE up
ip link set {ETHERNET_INTERFACE} up
ip link set dev $INTERFACE master br0
ip link set dev {ETHERNET_INTERFACE} master br0
ip addr add {IP_ADDRESS}/8 dev br0
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
else
  sed -e 's/{IP_ADDRESS}/'"${IP_ADDRESS}"'/' > /etc/tinc/gsnet/tinc-up <<'EOF'
#!/bin/sh
ip link add br0 type bridge
ip link set br0 up
ip link set $INTERFACE up
ip link set dev $INTERFACE master br0
ip addr add {IP_ADDRESS}/8 dev br0
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
fi
chmod +x /etc/tinc/gsnet/tinc-up

# tinc-down スクリプトの作成
# このシェルスクリプトはVPNセッションの終了時に実行される
if [ -n "${ETHERNET_INTERFACE}" == "" ]; then
  sed -e 's/{ETHERNET_INTERFACE}/'"${ETHERNET_INTERFACE}"'/' > /etc/tinc/gsnet/tinc-down <<'EOF'
#!/bin/sh
ip link set dev $INTERFACE nomaster
ip link set dev $INTERFACE down
ip link set dev {ETHERNET_INTERFACE} nomaster
ip link set dev br0 down
ip link del dev br0
EOF
else
  cat > /etc/tinc/gsnet/tinc-down <<'EOF'
#!/bin/sh
ip link set dev $INTERFACE nomaster
ip link set dev $INTERFACE down
ip link set dev br0 down
ip link del dev br0
EOF
fi
chmod +x /etc/tinc/gsnet/tinc-down

# VPNサーバのノード定義の作成
cat > /etc/tinc/gsnet/hosts/"${SERVER_NODE_NAME}" <<'EOF'
Address = kujira.club
Port = 655

-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEAoUqGa/tLwufcb3pPewoIpeGFVchFfpelLghvH3Wo9ddprNmn7EyV
MeNZ+sClZiyVl/UkMq7/j3iKUq4RyKOrqqLPxm+4GKnsoqQ8aOX3dEc3EabXeWK3
ypPNS+JSZcGRnUuJfyyuRklc89qeDfkzZIq+XxMXXN1pWsY0boMA5MHnC01ZysUh
HDgpCzlB9iRyN50J9aZXXX04jIazdC44MBdYfAYNXm6H2QbThw5fwsHsEPszEgCq
gqbHULsTiCafsMChUXYoXsWTY2Yy/bW743OboTSOHbjnNdLJUrfZgYv5lv95QU0s
xpJpbHj0O1NVoOsud5wtGudpNxoMtoR2mwIDAQAB
-----END RSA PUBLIC KEY-----
EOF

# 自ノードのノード定義の作成
# いまのところ特に設定する内容は無い
sed 's/{NODE_NAME}/'"${NODE_NAME}"'/' > /etc/tinc/gsnet/hosts/"${NODE_NAME}" <<'EOF'
# {NODE_NAME}
EOF

# 鍵ペアの生成
# tincの src/conf.c:541 を見ると標準入力と標準出力のどちらかが端末でない場合はデフォルトのファイル名を用いるようなので、`| cat` をつけている
sudo tincd -K -n gsnet | cat

# デバッグログの有効化
sed -i -e '/^# EXTRA="-d"$/ s/# //' /etc/default/tinc

# サービスの有効化
systemctl enable tinc@gsnet.service

# 完了メッセージを表示する
printf '\n'
printf 'tincのセットアップが完了しました\n'
printf '%s の管理者に以下の情報をコピーして渡してください\n\n' "${SERVER_NODE_NAME}"
printf '======== ここから ========\n'
printf '\e[34m' # 青くする
cat /etc/tinc/gsnet/hosts/"${NODE_NAME}"
printf '\e[m' # 元の色にする
printf '======== ここまで ========\n'
printf '\n'

printf 'Enterを押すとOSを再起動します'
read l
sudo reboot
