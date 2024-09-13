#!/bin/bash
# 不要改变下行的内容，保持在脚本开头

# 设置应用路径和加载必要的配置文件
APP_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; pwd)
source "${APP_PATH}/launcher/default.sh"
source "${APP_PATH}/.env"

########## 可配置部分 ##########

# 设置 Docker Compose 命令
DCC_COMMAND=$(setupDCC_COMMANDC docker-compose.yml)

# 加载子模块,空格分隔
subModules="prj-dashboard"

# 运行权限设置
ALLOW_ROOT=true
# ALLOW_ROOT=false

# 容器名称定义
BACKUP_CONTAINER="backups"
MYSQL_CONTAINER="mysql-app"

# 容器启动时需要建立的外部网络
GLOBAL_NETWORK=""

# 容器列表
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
查看init的运行账号 initConfigUserID
"

# 自定义函数定义

# 执行备份操作
startBackup() {
    echo '准备开始备份，如不能马上停止服务的，请在10秒内按 Ctrl+C 取消'
    sleep 10
    set -x
    $DCC_COMMAND exec "${BACKUP_CONTAINER}" backup
    set +x
}

# 初始化配置
initConfig() {
    ${DCC_COMMAND} run init
}

# 查看 init 容器的运行用户
initConfigUserID() {
    ${DCC_COMMAND} run -it init sh -c 'whoami'
}

########## 配置部分结束 ##########

# 不要改变下行的内容，保持在脚本结尾
go