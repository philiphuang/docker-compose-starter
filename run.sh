#!/bin/bash
# 不要改变下行的内容，保持在脚本开头
APP_PATH=$(cd $(dirname "${BASH_SOURCE:-$0}") || exit; pwd)
source "${APP_PATH}/launcher/default.sh"
source "${APP_PATH}/.env"

########## 以下是可修改的内容 ##########
DCC_COMMAND=$(setupDCC_COMMANDC docker-compose.yml)
echo $DCC_COMMAND

# 加载子模块,空格分隔
subModules="prj-dashboard"

# 是否允许以root身份运行
ALLOW_ROOT=true
# ALLOW_ROOT=false

BACKUP_CONTAINER="backups"
MYSQL_CONTAINER="mysql-app"

# 容器启动时需要建立的外部网络
GLOBAL_NETWORK=""

# 容器名称
CONTAINER_LIST="
nginx
mysql-app
mysql-user
springboot
tomcat
init
backups
"

# 操作清单,格式:中文菜单 自定义函数名
ACTION_LIST="
备份 startBackup
初始化配置 initConfig
查看init的运行账号  initConfigUserID
"

# 自定义函数
startBackup(){
    echo '准备开始备份，如不能马上停止服务的，请在10秒内^C'
    sleep 10
    set -x
    $DCC_COMMAND exec "${BACKUP_CONTAINER}" backup
    set +x
}

initConfig(){
    ${DCC_COMMAND} run init
}

initConfigUserID(){
    ${DCC_COMMAND} run -it init sh -C whoami
}

########## 以上是可修改的内容 ##########

# 不要改变下行的内容，保持在脚本结尾
go