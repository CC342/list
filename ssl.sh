#!/bin/bash

# 检查 acme.sh 是否已经安装
if [ ! -d "~/.acme.sh" ]; then
  echo "acme.sh 未安装，正在安装..."
  curl https://get.acme.sh | sh
fi

# 日志函数
LOGI() { echo -e "\033[32m[INFO]\033[0m $1"; }
LOGD() { echo -e "\033[34m[DEBUG]\033[0m $1"; }
LOGE() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# 提示用户输入域名
read -p "请输入域名:" CF_Domain
LOGI "你的域名为:${CF_Domain}"

# 提示用户输入 Cloudflare API 密钥
LOGD "请设置API密钥:"
read -p "Input your key here:" CF_GlobalKey
LOGD "你的API密钥为:${CF_GlobalKey}"

# 提示用户输入注册邮箱
LOGD "请设置注册邮箱:"
read -p "Input your email here:" CF_AccountEmail
LOGD "你的注册邮箱为:${CF_AccountEmail}"

# 设置默认 CA 为 Let's Encrypt
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
if [ $? -ne 0 ]; then
    LOGE "修改默认CA为Lets'Encrypt失败,脚本退出"
    exit 1
fi

# 设置 Cloudflare 凭据
export CF_Key="${CF_GlobalKey}"
export CF_Email="${CF_AccountEmail}"

# 使用 Cloudflare DNS 验证并签发证书
~/.acme.sh/acme.sh --issue --dns dns_cf -d "${CF_Domain}" -d "*.${CF_Domain}" --log
if [ $? -ne 0 ]; then
    LOGE "证书签发失败,脚本退出"
    rm -rf ~/.acme.sh/${CF_Domain}
    exit 1
else
    LOGI "证书签发成功,安装中..."
fi

# 创建证书存储目录
certPath="/root/cert"
mkdir -p "$certPath"

# 安装证书
~/.acme.sh/acme.sh --installcert -d "${CF_Domain}" -d "*.${CF_Domain}" \
    --ca-file "$certPath/ca.cer" \
    --cert-file "$certPath/${CF_Domain}.cer" \
    --key-file "$certPath/${CF_Domain}.key" \
    --fullchain-file "$certPath/fullchain.cer"
if [ $? -ne 0 ]; then
    LOGE "证书安装失败,脚本退出"
    rm -rf ~/.acme.sh/${CF_Domain}
    exit 1
else
    LOGI "证书安装成功,开启自动更新..."
fi

# 启用自动更新
~/.acme.sh/acme.sh --upgrade --auto-upgrade
if [ $? -ne 0 ]; then
    LOGE "自动更新设置失败,脚本退出"
    ls -lah "$certPath"
    chmod 755 "$certPath"
    exit 1
else
    LOGI "证书已安装且已开启自动更新,具体信息如下"
    ls -lah "$certPath"
    chmod 755 "$certPath"
fi
