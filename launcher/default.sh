DEFAULT_CONTAINER_LIST_TEXT="请选择对那个应用进行操作，请输入数字："

DEFAULT_ACTION_LIST_TEXT="请选择要进行的操作，请输入小写英文字母：
全部服务的启动、关闭、重启
单个容器的启动、关闭、重启
查看容器的日志
进入容器的shell
进入mysql的命令行
服务的状态、启动时间、IP、端口、镜像名称
"
ALLOW_ROOT=false

NETWORK_LIST=""

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

# ===========以下代码不需要修改
func0(){
    byebye
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
            $DCC_COMMAND logs -f --tail 300 ${dockerResult}
        fi
}

# 进入容器的shell
enterShell(){
        dockerResult=$(select_docker)
        if [ -n "${dockerResult}" ]; then
            $DCC_COMMAND exec ${dockerResult} sh
        fi
}

# 进入mysql的命令行
enterMySQLShell(){
    $DCC_COMMAND exec ${MYSQL_CONTAINER} mysql -u${MYSQL_USER} -p"${MYSQL_PWD}"
}

# 查看整个服务的状态和启动时间
showAllContainer(){
    $DCC_COMMAND ps
    echo
    echo "容器名称     IP    端口"
    echo "------------------------------------------------------------------------------------------"
    docker inspect --format='{{.Name}} - {{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $($DCC_COMMAND ps -q)
}

nothing_pressed(){
    # command(s) to be run if nothing is pressed after a certain time interval
    echo "没接收到输入，"
    byebye
}

byebye(){
    echo "程序已退出。"
    break;
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
    for item in ${@:2}; do         # Short for: for item in "$@"; do
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
        (( index >= 1 && index <= numItems )) 2>/dev/null || { echo "输入不正确，如需选择退出，请选择返回上一级." >&2; continue; }
        break
    done

  # Output the selected item, if any.
    [[ -n $index ]] && echo "$index"
}

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
    echo "这个函数"
}

go(){
    # 为安全起见，不允许root帐号运行
    if [ $ALLOW_ROOT = false ] && [ "root" = "$(whoami)" ] ; then
        echo '不允许root帐号运行'
        exit
    fi

    cd "${APP_PATH}"
    while true; do
        result=$(selectByIndex "${ACTION_LIST_TEXT}")
        fn_name="func${result}"

        case "$result" in
            0 ) byebye;;
            * ) declare -pF | grep -q "$fn_name" && ${fn_name};;
        esac
    done
}

