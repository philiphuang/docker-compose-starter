#!/bin/bash

########## 以下是可修改的内容 ##########

# 是否允许以root身份运行
ALLOW_ROOT=true

DCC_COMMAND="docker-compose -p ${PROJECT_NAME} -f restore.yml"

CONTAINER_LIST_TEXT="${DEFAULT_CONTAINER_LIST_TEXT}
${PROJECT_NAME}-mysql
${PROJECT_NAME}-restore
"

ACTION_LIST_TEXT="${DEFAULT_ACTION_LIST_TEXT}
全量还原
查看备份信息
删除3天以前的备份"

RESTORE_CONTAINER="${PROJECT_NAME}-restore"

func7(){
    docker volume rm ${PROJECT_NAME}_backup_volume ${PROJECT_NAME}_cache_volume ${PROJECT_NAME}_mysql_volume
    ${DCC_COMMAND} up -d ${RESTORE_CONTAINER}
    ${DCC_COMMAND} exec  ${RESTORE_CONTAINER} restore
    ${DCC_COMMAND} stop ${RESTORE_CONTAINER}
}

func8(){
    ${DCC_COMMAND} exec ${RESTORE_CONTAINER} list
}

func9(){
    ${DCC_COMMAND} exec ${RESTORE_CONTAINER} remove-older-than 3D --force
}
########## 以上是可修改的内容 ##########
