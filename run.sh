#!/bin/bash
# 不要改变下行的内容，保持在脚本开头
APP_PATH=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
source "${APP_PATH}/launcher/default.sh"
source "${APP_PATH}/.env"

########## 以下是可修改的内容 ##########

# 是否允许以root身份运行
ALLOW_ROOT=true
# ALLOW_ROOT=false

DCC_COMMAND="docker-compose -p ${PROJECT_NAME} -f docker-compose.yml"
BACKUP_CONTAINER="${PROJECT_NAME}-backups"
MYSQL_CONTAINER="${PROJECT_NAME}-mysql"

# 容器启动时需要建立的外部网络
NETWORK_LIST=""

# 容器名称
CONTAINER_LIST_TEXT="${DEFAULT_CONTAINER_LIST_TEXT}
${CONTAINER_LIST_TEXT}
"

# 操作清单，从第七项开始
ACTION_LIST_TEXT="${DEFAULT_ACTION_LIST_TEXT}
${ACTION_LIST_TEXT}
"

# 请按数字序号添加自定义的脚本，第一个自定义脚本的序号是7
func7(){
    echo '准备开始备份，如不能马上停止服务的，请在10秒内^C'
    sleep 10
    set -x
    $DCC_COMMAND exec ${BACKUP_CONTAINER} backup
    set +x
}

func8(){
    echo "function 8"
}

########## 以上是可修改的内容 ##########

# 不要改变下行的内容，保持在脚本结尾
[ -n "${1}" ] && source "${APP_PATH}/${1}"
go