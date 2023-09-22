#!/bin/bash

set -ex

########################################################################################################################
# validate arguments ###################################################################################################
########################################################################################################################

# 引数チェック1
if [ $# -lt 1  ]; then
  echo "デプロイ先環境を指定してください。" 1>&2
  exit 1
fi

# 引数チェック2
if [ $1 == "production" -o $1 == "staging" -o $1 == "testing" -o $1 == "develop" ]; then
  if [ $# -ne 2  ]; then
    echo $1"では復号キーの指定が必要です。" 1>&2
    exit 1
  fi
elif [ $1 == "local" ]; then
  if [ $# -ne 1  ]; then
    echo $1"では復号キーを指定できません。" 1>&2
    exit 1
  fi
  if [ ! -e ".env" ]; then
    echo $1"では.envファイルが必要です" 1>&2
    exit 1
  fi

else
  echo $1":想定されていないデプロイ先" 1>&2
  exit 1
fi

echo "Environment:"$1

########################################################################################################################
# deploy process #######################################################################################################
########################################################################################################################
# Step1. decrypt .env
if [ $1 == "production" -o $1 == "staging" -o $1 == "testing" -o $1 == "develop" ]; then
    php artisan -q env:decrypt --force --env=$1 --key=$2
    mv .env.$1 .env
fi
source ./.env
echo $APP_NAME

# Step2. cache
# clear cache
php artisan cache:clear
php artisan config:clear
php artisan view:clear
php artisan route:clear

if [ $1 == "production" -o $APP_ENV == "staging" ]; then
  # crete cache
  php artisan config:cache
  php artisan route:cache
  php artisan view:cache
else
  # do nothing
  echo $1":No cache."
fi

# Step3. Execute migration
php artisan migrate --force

# Step4. build resources
# local,testingでは別のコマンドを叩いたほうが良いかも
npm run build
