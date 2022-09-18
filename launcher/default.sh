#!/bin/bash
DEFAULT_CONTAINER_LIST_TEXT="请选择对那个应用进行操作，请输入数字："

DEFAULT_ACTION_LIST_TEXT="请选择要进行的操作，请输入小写英文字母：
全部容器的启动、关闭、重启
单个容器的启动、关闭、重启
查看容器的日志
进入容器的shell
进入mysql的命令行
容器的状态、启动时间、IP、端口、镜像名称
重启本脚本
"
ALLOW_ROOT=false

NETWORK_LIST=""

green(){
    echo -e "\033[32m$1\033[0m"
}

red(){
    echo -e "\033[31m$1\033[0m"
}

func1(){
    restartWholeService
}

func2(){
    restartSingleService
}

func3(){
    showLogs
}

func4(){
    enterShell
}

func5(){
    enterMySQLShell
}

func6(){
    showAllContainer
}

func7(){
    red "重新载入所有Shell脚本"
    $(basename $0) && exit 255
}
# ===========以下代码不需要修改

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
            $DCC_COMMAND logs -f --tail 300 ${dockerResult}
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
    if [[ true = $CONNECT_MYSQL_AS_ROOT ]]; then
        docker exec -it "${dockerResult}" env LANG=C.UTF-8 mysql -uroot -p"${MYSQL_ROOT_PASSWORD}"
    else
        docker exec -it "${dockerResult}" env LANG=C.UTF-8 mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}"
    fi
}

# 执行mysql的命令行，参数：数据库，SQL命令
execSQL(){
    dockerResult=$($DCC_COMMAND ps -q "${MYSQL_HOST}")
    docker exec -i "${dockerResult}" mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" ${1} <<EOF
    $2
EOF
}

# 查看整个服务的状态和启动时间
showAllContainer(){
    result=$($DCC_COMMAND ps)
    # result需带双信号才保留回车
    if [[ 1 -eq $(echo "$result" | wc -l) ]]; then
        red "没有容器运行"
    else
        echo "$result"
        if [[ true = $reportMemoryUsage ]]; then
            echo
            docker stats  --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $($DCC_COMMAND ps -q)
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
    options=($(awk '{print $1}' <<< "$1") "返回上级菜单或退出")
    index=$(selectWithDefault "${options[@]}")

    (( index == $((${#options[@]}-1)) )) && index=0
    echo "$index"
}

selectByContent() {
    declare -a options
    options=($(awk '{print $1}' <<< "$1") "返回上级菜单或退出")
    index=$(selectWithDefault "${options[@]}")

    result=${options[$index]}
    (( index == $((${#options[@]}-1)) )) && result=""
    echo "$result"
}

select_docker(){
    result=$(selectByContent "${CONTAINER_LIST_TEXT}")
    echo $result
}

# Will wait for this interval, then run default action
# 参考：https://superuser.com/questions/161659/framework-for-interactive-shell-script-bash

# 暂不使用
createGlobalNetwork(){
    for nw in $GLOBAL_NETWORK; do
        if docker network inspect --format {{.Name}} $(docker network ls -q) | grep -qi $nw; then
            echo "network $nw already existed since $(docker network inspect --format {{.Created}} $nw)"
        else
            echo "newly created network $nw with following id:"
            docker network create $nw
        fi
    done
}

showAllContainerIP(){
    red "这个函数已经废弃，请使用showAllContainer"
}

go(){
    # 为安全起见，不允许root帐号运行
    if [ $ALLOW_ROOT = false ] && [ "root" = "$(whoami)" ] ; then
        red '不允许root帐号运行'
        return
    fi

    cd "${APP_PATH}"
    while true; do
        result=$(selectByIndex "${ACTION_LIST_TEXT}")
        fn_name="func${result}"

        case "$result" in
            0 ) red "程序已退出。";break;;
            # 参考：https://askubuntu.com/questions/356800/how-to-completely-restart-script-from-inside-the-script-itself
            7 ) red "重新载入所有Shell脚本"; exec $(basename $0) && exit 255;;
            "" ) continue;;
            * ) declare -pF | grep -q "$fn_name" && ${fn_name};;
        esac
    done
}