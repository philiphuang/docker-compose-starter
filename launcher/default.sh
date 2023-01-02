#!/bin/bash
DEFAULT_CONTAINER_LIST_TEXT="请选择对那个应用进行操作，请输入数字："
DEFAULT_ACTION_LIST_TEXT="请选择要进行的操作，请输入小写英文字母："
DEFAULT_ACTION_LIST="全部容器的启动、关闭、重启 restartWholeService
单个容器的启动、关闭、重启 restartSingleService
查看容器的日志 showLogs
进入容器的shell enterShell
进入mysql的命令行 enterMySQLShell
容器的状态、启动时间、IP、端口、镜像名称 showAllContainer
重启本脚本 reloadAllScript"
declare ALLOW_ROOT=false
declare subModules
declare GLOBAL_NETWORK
declare CONTAINER_LIST_TEXT
declare ACTION_LIST_TEXT

green(){
    echo -e "\033[32m$1\033[0m"
}

red(){
    echo -e "\033[31m$1\033[0m"
}

# 整个服务的启动、关闭、重启
restartWholeService(){
    ACTIONS="请选择要进行的操作，请输入小写英文字母：
    重启
    启动
    关闭"
    actionResult=$(selectByIndex "$ACTIONS")

    case $actionResult in
        1) $DCC_COMMAND down && $DCC_COMMAND up -d;;
        2) createGlobalNetwork && $DCC_COMMAND up -d;;
        3) $DCC_COMMAND down;;
    esac
}

# 单个容器的启动、关闭、重启
restartSingleService(){
    ACTIONS="请选择要进行的操作，请输入小写英文字母：
    重启
    启动
    关闭"
    actionResult=$(selectByIndex "$ACTIONS")

    if [ "${actionResult}" -ne 0 ]; then
        dockerResult=$(select_docker)
        if [ -n "${dockerResult}" ]; then
            case $actionResult in
                1) $DCC_COMMAND stop "${dockerResult}" && $DCC_COMMAND up -d "${dockerResult}";;
                2) createGlobalNetwork && $DCC_COMMAND up -d "${dockerResult}";;
                3) $DCC_COMMAND stop "${dockerResult}";;
            esac
        fi
    fi
}

# 查看容器的日志
showLogs(){
        dockerResult=$(select_docker)
        if [ -n "${dockerResult}" ]; then
            $DCC_COMMAND logs -f --tail 300 "${dockerResult}"
        fi
}

# 进入容器的shell
enterShell(){
        dockerResult=$(select_docker)
        if [ -n "${dockerResult}" ]; then
            dockerResult=$($DCC_COMMAND ps -q "${dockerResult}")
            # 如果执行bash失败，则压制错误信息，然后执行sh
            docker exec -it "${dockerResult}" bash 2 > /dev/null
            if [ 0 -ne $? ]; then
                docker exec -it "${dockerResult}" sh
            fi
        fi
}

# 进入mysql的命令行
enterMySQLShell(){
    dockerResult=$($DCC_COMMAND ps -q "${MYSQL_HOST}")
    # docker中mysql容器查询时中文乱码解决方法 https://blog.csdn.net/weixin_44760538/article/details/106901383
    if [[ true = ${CONNECT_MYSQL_AS_ROOT} ]]; then
        docker exec -it "${dockerResult}" env LANG=C.UTF-8 mysql -uroot -p"${MYSQL_ROOT_PASSWORD}"
    else
        docker exec -it "${dockerResult}" env LANG=C.UTF-8 mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}"
    fi
}

# 执行mysql的命令行，参数：数据库，SQL命令
execSQL(){
    dockerResult=$($DCC_COMMAND ps -q "${MYSQL_HOST}")
    if [[ true = ${CONNECT_MYSQL_AS_ROOT} ]]; then
        docker exec -i "${dockerResult}"  env LANG=C.UTF-8 mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" "${1}" <<EOF
        $2
EOF
    else
        docker exec -i "${dockerResult}"  env LANG=C.UTF-8 mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${1}" <<EOF
        $2
EOF
    fi

}

# 查看整个服务的状态和启动时间
showAllContainer(){
    result=$($DCC_COMMAND ps)
    # result需带双信号才保留回车
    if [[ 1 -eq $(echo "$result" | wc -l) ]]; then
        red "没有容器运行"
    else
        echo "$result"
        if [[ true = ${REPORT_MEMORY_USAGE} ]]; then
            echo
            docker stats  --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(${DCC_COMMAND} ps -q)
        fi
        echo
        echo "进程ID     容器名称     IP"
        echo "------------------------------------------------------------------------------------------"
        docker inspect --format="{{ .State.Pid }}  {{.Name}} - {{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}" $($DCC_COMMAND ps -q)
    fi
    }

# 参考：https://stackoverflow.com/questions/42789273/bash-choose-default-from-case-when-enter-is-pressed-in-a-select-prompt/42790075#42790075

# Custom `select` implementation that allows *empty* input.
# Pass the choices as individual arguments.
# Output is the chosen item, or "", if the user just pressed ENTER.
# Example:
#    choice=$(menuSelect 'one' 'two' 'three')
selectWithDefault() {
    local item i=0 numItems=$#
    declare -a indec
    indec=({a..z})

    printf "\n%s\n" "=============================" >&2
    # Print numbered menu items, based on the arguments passed.
    for item in "${@:2}"; do         # Short for: for item in "$@"; do
      printf '%s ) %s\n' "${indec[$((i++))]}" "$item"
    done >&2 # Print to stderr, as `select` does.

    # Prompt the user for the index of the desired item.
    while :; do
        printf %s "$1" >&2 # Print the prompt string to stderr, as `select` does.
        read -n1 -r index
        # Make sure that the input is either empty or that a valid index was entered.
        echo >&2
        [[ -z $index ]] && break  # empty input
        index=$((`printf "%d" "'$index"`-97+1))
        (( index >= 1 && index <= numItems )) 2>/dev/null || { red "输入不正确，如需选择退出，请选择返回上一级." >&2; continue; }
        break
    done

  # Output the selected item, if any.
    [[ -n $index ]] && echo "$index"
}

# 参数 ActionList：选择项，自动加上abc
selectByIndex() {
    declare -a options
    options=($(awk '{for (i=1; i<=NF; i++) print $i}' <<< "$1") "返回上级菜单或退出")
    index=$(selectWithDefault "${options[@]}")

    (( index == $((${#options[@]}-1)) )) && index=0
    echo "$index"
}

selectByContent() {
    declare -a options
    options=($(awk '{for (i=1; i<=NF; i++) print $i}' <<< "$1") "返回上级菜单或退出")
    index=$(selectWithDefault "${options[@]}")

    result=${options[$index]}
    (( index == $((${#options[@]}-1)) )) && result=""
    echo "$result"
}

select_docker(){
    result=$(selectByContent "${CONTAINER_LIST_TEXT}")
    echo "$result"
}

# Will wait for this interval, then run default action
# 参考：https://superuser.com/questions/161659/framework-for-interactive-shell-script-bash

# 检查缺失的全局网路，并建立之
createGlobalNetwork(){
    for nw in $GLOBAL_NETWORK; do
        if docker network inspect --format {{.Name}} $(docker network ls -q) | grep -qi $nw; then
            # echo "全局网络“$nw”已存在，建于$(docker network inspect --format {{.Created}} $nw)"
            echo -n
        else
            echo "新建全局网络：${nw} ，ID为:"
            docker network create "${nw}"
        fi
    done
}

# 加载子模块的代码
laodSubModules(){
    for dir in "${@}"; do
        [[ -f $dir/.env ]] && source "$dir"/.env
        [[ -f $dir/docker-compose.yml ]] && DCC_COMMAND="${DCC_COMMAND} -f $dir/docker-compose.yml"
        [[ -f $dir/run.sh ]] && source "$dir"/run.sh

        CONTAINER_LIST_TEXT="${CONTAINER_LIST_TEXT} ${CONTAINER_LIST}"
        ACTION_LIST_TEXT="${ACTION_LIST_TEXT} ${ACTION_LIST}"
    done
}

# 参考：https://askubuntu.com/questions/356800/how-to-completely-restart-script-from-inside-the-script-itself
reloadAllScript(){
    red "重新载入所有Shell脚本"
    exec $(basename "$0") && exit 255
}

go(){
    # 为安全起见，不允许root帐号运行
    if [ $ALLOW_ROOT = false ] && [ "root" = "$(whoami)" ] ; then
        red '不允许root帐号运行'
        return
    fi

    # 加载子模块
    laodSubModules "${subModules}"
    CONTAINER_LIST_TEXT="${DEFAULT_CONTAINER_LIST_TEXT} ${CONTAINER_LIST_TEXT}"
    ACTION_LIST_TEXT="${DEFAULT_ACTION_LIST} ${ACTION_LIST_TEXT}"

    ACTION_LIST="${DEFAULT_ACTION_LIST_TEXT}"
    FUNC_ARRAY=()
    # 使用 awk 将长字符串切分为数组，跳过重复的空格和换行
    Input_Array=($(awk '{for (i=1; i<=NF; i++) print $i}' <<< "$ACTION_LIST_TEXT"))

    for ((i=0; i<${#Input_Array[@]}; i++)); do
    if [[ $((i % 2)) -eq 0 ]]; then
        # 如果是偶数序列，将元素加入ACTION_LIST字符串
        ACTION_LIST="${ACTION_LIST} ${Input_Array[i]}"
    else
        # 如果是奇数序列，将元素加入FUNC_ARRAY数组
        FUNC_ARRAY+=("${Input_Array[i]}")
    fi
    done

    while true; do
        result=$(selectByIndex "${ACTION_LIST}")

        case "$result" in
            0 ) red "程序已退出。";break;;
            "" ) continue;;
            * ) fn_name=${FUNC_ARRAY[$((result-1))]}; declare -pF | grep -q "$fn_name" && ${fn_name};;
        esac
    done
}