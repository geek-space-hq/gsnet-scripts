#!/bin/sh

# 使い方:
#   curl -L https://raw.githubusercontent.com/geek-space-hq/gsnet-scripts/master/generate_welcome_nijisanji.sh > /tmp/welcome_gen.sh; sudo sh /tmp/welcome_gen.sh -h
#

cmdname="$(basename "$0")"

DEFAULT_DEST_DIR="/var/www/html"

while getopts n:a:c:b:i:h OPT; do
  case $OPT in
  "n" ) FLG_n="TRUE"; VALUE_n=${OPTARG} ;;
  "a" ) FLG_a="TRUE"; VALUE_a=${OPTARG} ;;
  "c" ) FLG_c="TRUE"; VALUE_c=${OPTARG} ;;
  "b" ) FLG_b="TRUE"; VALUE_b=${OPTARG} ;;
  "i" ) FLG_i="TRUE"; VALUE_i=${OPTARG} ;;
  "h" ) echo "使い方: ${cmdname} [-n host_name] [-a ip_address] [-c color] [-b background_color] [-i image_link]"
        echo "        ${cmdname} [-h]"
        echo "    -n host_name        ページに出力するホスト名"
        echo "    -a ip_address       ページに出力するIPアドレス"
        echo "    -c color            ページの文字色"
        echo "    -b background_color ページの背景色"
        echo "    -i image_link       ライバーの画像リンク"
        echo "    -h                  このヘルプを表示する"
        exit 0 ;;
  * ) :
  esac
done

if [ "${DEST_DIR}" = "" ]; then
  DEST_DIR="${DEFAULT_DEST_DIR}"
fi

if [ "${FLG_n}" = "TRUE" ]; then
  HOST_NAME="${VALUE_n}"
else
  echo "エラー: -n を指定する必要があります" >&2
  exit 1
fi

if [ "${FLG_a}" = "TRUE" ]; then
  IP_ADDRESS="${VALUE_a}"
else
  echo "エラー: -a を指定する必要があります" >&2
  exit 1
fi

if [ "${FLG_c}" = "TRUE" ]; then
  COLOR="${VALUE_c}"
else
  echo "エラー: -c を指定する必要があります" >&2
  exit 1
fi

if [ "${FLG_b}" = "TRUE" ]; then
  BG_COLOR="${VALUE_b}"
else
  echo "エラー: -b を指定する必要があります" >&2
  exit 1
fi

if [ "${FLG_i}" = "TRUE" ]; then
  IMG_LINK="${VALUE_i}"
else
  echo "エラー: -i を指定する必要があります" >&2
  exit 1
fi

sed -e 's/{HOST_NAME}/'"${HOST_NAME}"'/' \
  -e 's/{IP_ADDRESS}/'"${IP_ADDRESS}"'/' \
  -e 's/{COLOR}/'"${COLOR}"'/' \
  -e 's/{BG_COLOR}/'"${BG_COLOR}"'/' \
  -e 's!{IMG_LINK}!'"${IMG_LINK}"'!' \
  > "${DEST_DIR}"/index.html <<'EOF'
<!DOCTYPE html>
<html lang="ja">
  <head>
    <title>Welcome to {HOST_NAME}!</title>
    <style>
      body{
        background-color: {BG_COLOR};
        color: {COLOR};
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
      }
      img{
        width: 100%;
      }
      a:link{
        color: {COLOR};
      }
      a:visited{
        color: {COLOR};
      }
      a:hover{
        color: {COLOR};
      }
      a:active{
        color: {COLOR};
      }
    </style>
  </head>
  <body>
    <h1>{HOST_NAME}[<a href="/info/">{IP_ADDRESS}</a>]へようこそ</h1>
    <img src="{IMG_LINK}">
  </body>
</html>
EOF

mkdir -p "${DEST_DIR}"/info

sed -e 's/{HOST_NAME}/'"${HOST_NAME}"'/' \
  -e 's/{COLOR}/'"${COLOR}"'/' \
  -e 's/{BG_COLOR}/'"${BG_COLOR}"'/' \
  > "${DEST_DIR}"/info/index.html <<'EOF'
<!DOCTYPE html>
<html>
  <head>
    <title>I'm {HOST_NAME} on GSNet.</title>
    <style>
      body {
        background-color: {BG_COLOR};
        color: {COLOR};
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
      }
    </style>
  </head>
  <body>
    <h1>I'm {HOST_NAME}!</h1>
    <h2>概要</h2>
    <ul>
      <li>sample text</li>
    </ul>
    <h2>ハードウェア情報</h2>
    <ul>
      <li>sample text</li>
    </ul>
    <p><em>Thank you for accessing {HOST_NAME}.</em><p>
  </body>
</html>
EOF
