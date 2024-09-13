#!/bin/bash

# 定义默认提示和操作列表
DEFAULT_CONTAINER_PROMPT="请选择对那个应用进行操作，请输入数字："
DEFAULT_ACTION_PROMPT="请选择要进行的操作，请输入小写英文字母："
DEFAULT_ACTION_LIST="全部容器的启动、关闭、重启 restartWholeService
单个容器的启动、关闭、重启 restartSingleService
查看容器的日志 showLogs
进入容器的shell enterShell
进入mysql的命令行 enterMySQLShell
容器的状态、启动时间、IP、端口、镜像名称 showAllContainer
重启本脚本 reload_scripts"

# 声明全局变量
declare ALLOW_ROOT=false
declare subModules
declare GLOBAL_NETWORK
declare CONTAINER_LIST_ALL
declare ACTION_LIST_ALL

# 输出绿色文本
green(){
    echo -e "\033[32m$1\033[0m"
}

# 输出红色文本
red(){
    echo -e "\033[31m$1\033[0m"
}

# 重启整个服务
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

# 重启单个容器
restartSingleService(){
    ACTIONS="请选择要进行的操作，请输入小写英文字母：
    重启
    启动
    关闭"
    actionResult=$(selectByIndex "$ACTIONS")

    if [ "${actionResult}" -ne 0 ]; then
        dockerResult=$(selectDocker)
        if [ -n "${dockerResult}" ]; then
            case $actionResult in
                1) $DCC_COMMAND stop "${dockerResult}" && $DCC_COMMAND up -d "${dockerResult}";;
                2) createGlobalNetwork && $DCC_COMMAND up -d "${dockerResult}";;
                3) $DCC_COMMAND stop "${dockerResult}";;
            esac
        fi
    fi
}

# 查看容器日志
showLogs(){
    dockerResult=$(selectDocker)
    if [ -n "${dockerResult}" ]; then
        $DCC_COMMAND logs -f --tail 300 "${dockerResult}"
    fi
}

# 进入容器shell
enterShell(){
    dockerResult=$(selectDocker)
    if [ -n "${dockerResult}" ]; then
        dockerResult=$($DCC_COMMAND ps -q "${dockerResult}")
        # 尝试执行bash，如果失败则执行sh
        docker exec -it "${dockerResult}" bash 2> /dev/null || docker exec -it "${dockerResult}" sh
    fi
}

# 进入MySQL命令行
enterMySQLShell(){
    dockerResult=$($DCC_COMMAND ps -q "${MYSQL_HOST}")
    # 解决中文乱码问题
    if [[ true = "${CONNECT_MYSQL_AS_ROOT}" ]]; then
        docker exec -i "${dockerResult}" env LANG=C.UTF-8 mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" "${1}" <<EOF
        $2
EOF
    else
        docker exec -i "${dockerResult}" env LANG=C.UTF-8 mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${1}" <<EOF
        $2
EOF
    fi
}

# 执行SQL命令
execSQL(){
    dockerResult=$($DCC_COMMAND ps -q "${MYSQL_HOST}")
    if [[ true = "${CONNECT_MYSQL_AS_ROOT}" ]]; then
        docker exec -i "${dockerResult}" env LANG=C.UTF-8 mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" "${1}" <<EOF
        $2
EOF
    else
        docker exec -i "${dockerResult}" env LANG=C.UTF-8 mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${1}" <<EOF
        $2
EOF
    fi
}

# 显示所有容器状态
showAllContainer(){
    result=$($DCC_COMMAND ps)
    # result需带双信号才保留回车
    if [[ 1 -eq $(echo "$result" | wc -l) ]]; then
        red "没有容器运行"
    else
        echo "$result"
        if [[ true = ${REPORT_MEMORY_USAGE} ]]; then
            echo
            docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(${DCC_COMMAND} ps -q)
        fi
        echo
        echo "进程ID     容器名称     IP"
        echo "------------------------------------------------------------------------------------------"
        docker inspect --format="{{ .State.Pid }}  {{.Name}} - {{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}" $($DCC_COMMAND ps -q)
    fi
}

# 自定义选择函数
selectWithDefault() {
    # 初始化局部变量
    local item i=0 numItems=$#
    # 声明一个数组用于存储选项的标识符
    declare -a indec
    # 使用大括号扩展创建a到z的字母数组，然后添加0到9的数字
    indec=({a..z} {0..9})

    printf "\n%s\n" "=============================" >&2
    # 遍历所有参数（除第一个参数外），打印选项
    for item in "${@:2}"; do
      # 使用字母或数字作为选项的标识，打印选项内容
      printf '%s ) %s\n' "${indec[$((i++))]}" "$item"
      # 如果选项数量超过了可用的标识符，输出提示信息并退出循环
      if [[ $i -ge ${#indec[@]} ]]; then
        red "警告：选项数量超过可显示的最大数量(${#indec[@]})。部分选项未显示。" >&2
        break
      fi
    done >&2

    # 无限循环，直到用户输入有效选项或者选择退出
    while :; do
        # 打印提示信息（第一个参数）
        printf %s "$1" >&2
        # 读取用户输入的一个字符
        read -n1 -r index
        # 打印换行
        echo >&2
        # 如果用户没有输入（直接回车），则退出循环
        [[ -z $index ]] && break
        # 将用户输入转换为对应的数字索引
        if [[ $index =~ [a-z] ]]; then
            # 如果是字母，转换为1-26
            index=$((`printf "%d" "'$index"`-96))
        elif [[ $index =~ [0-9] ]]; then
            # 如果是数字，转换为27-36
            index=$((index + 26))
        else
            # 如果既不是字母也不是数字，视为无效输入
            index=0
        fi
        # 检查输入是否在有效范围内
        (( index >= 1 && index <= numItems && index <= ${#indec[@]} )) 2>/dev/null || { red "输入不正确，如需选择退出，请选择返回上一级." >&2; continue; }
        # 如果输入有效，退出循环
        break
    done

    # 如果index不为空（用户选择了有效选项），则输出index
    [[ -n $index ]] && echo "$index"
}

# 根据索引选择
selectByIndex() {
    declare -a options
    options=($(awk '{for (i=1; i<=NF; i++) print $i}' <<< "$1") "返回上级菜单或退出")
    index=$(selectWithDefault "${options[@]}")

    (( index == $((${#options[@]}-1)) )) && index=0
    echo "$index"
}

# 根据内容选择
selectByContent() {
    declare -a options
    options=($(awk '{for (i=1; i<=NF; i++) print $i}' <<< "$1") "返回上级菜单或退出")
    index=$(selectWithDefault "${options[@]}")

    result=${options[$index]}
    (( index == $((${#options[@]}-1)) )) && result=""
    echo "$result"
}

# 选择Docker容器
selectDocker(){
    result=$(selectByContent "${CONTAINER_LIST_ALL}")
    echo "$result"
}

# 创建全局网络
createGlobalNetwork(){
    # 遍历 GLOBAL_NETWORK 变量中定义的所有网络
    for nw in $GLOBAL_NETWORK; do
        # 检查网络是否已存在
        # docker network ls -q 列出所有网络的ID
        # docker network inspect --format {{.Name}} 获取每个网络的名称
        # grep -qi 进行不区分大小写的静默搜索
        if docker network inspect --format {{.Name}} $(docker network ls -q) | grep -qi $nw; then
            # 如果网络已存在，不做任何操作
            # echo -n 输出一个空字符串，实际上不产生任何输出
            echo -n
        else
            # 如果网络不存在，创建新网络
            echo "新建全局网络：${nw} ，ID为:"
            # 创建新的 Docker 网络并输出网络 ID
            docker network create "${nw}"
        fi
    done
}

# 加载子模块
laodSubModules(){
    CONTAINER_LIST_ALL="${CONTAINER_LIST_ALL} ${CONTAINER_LIST}"
    ACTION_LIST_ALL="${ACTION_LIST_ALL} ${ACTION_LIST}"

    for dir in "${@}"; do
        CONTAINER_LIST=""
        ACTION_LIST=""
        if [ -f "${APP_PATH}/$dir/.env" ]; then
            source "${APP_PATH}/$dir/.env"
            export $(grep -v '^#' "${APP_PATH}/$dir/.env" | xargs)
        fi

        if [ -f "${APP_PATH}/$dir/docker-compose.yml" ]; then
            DCC_COMMAND="${DCC_COMMAND} -f $dir/docker-compose.yml"
        fi

        if [ -f "${APP_PATH}/$dir/run.sh" ]; then
            # shellcheck source=../*/run.sh
            source "${APP_PATH}/$dir/run.sh"
        fi

        CONTAINER_LIST_ALL="${CONTAINER_LIST_ALL} ${CONTAINER_LIST}"
        ACTION_LIST_ALL="${ACTION_LIST_ALL} ${ACTION_LIST}"
    done
}

# 重新加载脚本
reload_scripts() {
    red "重新载入所有Shell脚本"
    exec "$(realpath "$0")" "$@"
    exit 255
}

# 设置 docker-compose 命令,如果docker版本够新,则优先使用docker compose,如果没有则采用docker-compose,如果都不存在则报错
setupDCC_COMMANDC(){
    if [ "$#" -eq 0 ]; then
        echo "Error: Missing Docker-Compose.yaml as first argument"
        exit 1
    else
        # 判断是否存在 docker compose 命令
        if command -v docker &> /dev/null && docker compose version &> /dev/null
        then
            DCC_COMMAND="docker compose -p ${PROJECT_NAME} -f $1"
        elif command -v docker-compose &> /dev/null
        then
            DCC_COMMAND="docker-compose -p ${PROJECT_NAME} -f $1"
        else
            echo "Neither docker-compose nor docker compose command is available"
            exit 1
        fi
        echo "$DCC_COMMAND"
    fi
}

# 主函数
go(){
    # 为安全起见，不允许root帐号运行
    if [ $ALLOW_ROOT = false ] && [ "root" = "$(whoami)" ] ; then
        red '不允许root帐号运行'
        return
    fi

    # 加载子模块
    laodSubModules "${subModules}"
    CONTAINER_LIST_ALL="${DEFAULT_CONTAINER_PROMPT} ${CONTAINER_LIST_ALL}"
    ACTION_LIST_ALL="${DEFAULT_ACTION_LIST} ${ACTION_LIST_ALL}"

    ACTION_LIST="${DEFAULT_ACTION_PROMPT}"
    FUNC_ARRAY=()
    # 使用 awk 将长字符串切分为数组，跳过重复的空格和换行
    Input_Array=($(awk '{for (i=1; i<=NF; i++) print $i}' <<< "$ACTION_LIST_ALL"))

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