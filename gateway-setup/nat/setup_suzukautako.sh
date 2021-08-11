#!/bin/sh
# base: https://gist.github.com/chun37/f7c4fc3aaeabd6e39ca5ad42b5d2f85c
#
# 使い方:
#   curl -L https://raw.githubusercontent.com/geek-space-hq/gsnet-scripts/master/gateway-setup/nat/setup_suzukautako.sh > /tmp/setup_tinc.sh; sudo sh /tmp/setup_tinc.sh <ノード名> <IPアドレス>
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
SERVER_NODE_NAME="suzukautako"

printf 'NODE_NAME: %s\n' "${NODE_NAME}"
printf 'IP_ADDRESS: %s\n' "${IP_ADDRESS}"

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
sed 's/{IP_ADDRESS}/'"${IP_ADDRESS}"'/' > /etc/tinc/gsnet/tinc-up <<'EOF'
#!/bin/sh
ip link add br0 type bridge
ip link set br0 up
ip link set $INTERFACE up
ip link set dev $INTERFACE master br0
ip link set dev eth1 master br0
ip addr add {IP_ADDRESS}/8 dev br0
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables-restore < /etc/tinc/gsnet/nat.iptables
EOF
chmod +x /etc/tinc/gsnet/tinc-up

# iptables(NAT)の設定ファイルの作成
cat > /etc/tinc/gsnet/nat.iptables <<'EOF'
# Generated by xtables-save v1.8.2 on Thu Jul 15 00:21:02 2021
*filter
:INPUT ACCEPT [46687:11733996]
:FORWARD ACCEPT [1617:74797]
:OUTPUT ACCEPT [295135:228581507]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i br0 -o eth0 -j DROP
COMMIT
# Completed on Thu Jul 15 00:21:02 2021
# Generated by xtables-save v1.8.2 on Thu Jul 15 00:21:02 2021
*nat
:PREROUTING ACCEPT [15990:4356696]
:INPUT ACCEPT [12944:3533125]
:POSTROUTING ACCEPT [410:45315]
:OUTPUT ACCEPT [175:24583]
-A POSTROUTING -o br0 -j MASQUERADE
COMMIT
# Completed on Thu Jul 15 00:21:02 2021
# Generated by xtables-save v1.8.2 on Thu Jul 15 00:21:02 2021
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed on Thu Jul 15 00:21:02 2021
# Generated by xtables-save v1.8.2 on Thu Jul 15 00:21:02 2021
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed on Thu Jul 15 00:21:02 2021
EOF

# tinc-down スクリプトの作成
# このシェルスクリプトはVPNセッションの終了時に実行される
cat > /etc/tinc/gsnet/tinc-down <<'EOF'
#!/bin/sh
ip link set dev $INTERFACE nomaster
ip link set dev $INTERFACE down
ip link set dev eth1 nomaster
ip link set dev br0 down
ip link del dev br0
EOF
chmod +x /etc/tinc/gsnet/tinc-down

# VPNサーバのノード定義の作成
cat > /etc/tinc/gsnet/hosts/"${SERVER_NODE_NAME}" <<'EOF'
Address = 140.227.70.225
Port = 655

-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEAzzPh12lCjoWmnkyOFxQ4+ySQQ4WcYh11AdOoyGLTZCX3yA+jH6NO
2EJ6hx4kdvSEQfU1YRR5FJkD28nNsKYAoMhEsbRIJjn/uTCTw0NHFw6MbfDPgTlK
vqNhijTY3h3Z5mtciMm5Ooow4ZXywih3Ty2c8Gvc77jMMlWtZ+ay6XsSvFT26Cit
oFzKf2uGUT6JoibzTjZcXwfq/aMB4HDG5p5gpA80uYxrwbDnH5TTw6ZbKN2A0IZh
xgr5thmIcn+ihGgbJThZhQJ+UfRSlEYOx1TH5oRhUgcWvnNCuDpD7N2MAtZFSGPA
ouErT6lQ9C5K0qVk6n7Ou8UkvcZHO4qBaQIDAQAB
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