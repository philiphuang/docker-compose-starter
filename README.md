# Docker-Compose Starter

DC-Starter是帮你运行Docker-Compose的懒人脚本，不用死背命令，一键启动、关闭容器、查看日志、检查容器状态。

![主菜单](https://gitee.com/philiphuang/docker-compose-starter/raw/master/docs/done-first-start.png)

## 前言

做开发的同学经常要搭建本地运行环境，虽然Docker可以简化工作，但也带来了一堆要记忆的命令和参数。

  1. 如果你不想手敲mysql命令行： ``` $ docker run -it --network some-network --rm mysql mysql -hsome-mysql -uexample-user -p ```。

  2. 或者NAS稳定运行三个月后，重启，你已经想不起三个月前启动jellyfin的命令： ``` $ docker run -d --name jellyfin -v /volume1/docker/jellyfin/config:/config -v /volume1/docker/je-llyfin/cache:/cache -v /volume1/video:/video -p 8096:8096 -p 8920:8920 --device=/dev/dri/renderD128 --restart unless-stopped jellyfin/jellyfin ```

  3. 你就找对地方了。

## 快速开始

只需三步，你就可以拥有一套具备三层结构的后台应用：

1. 拉取项目代码：

    ```
    git clone https://github.com/philiphuang/docker-compose-starter.git
    ```

2. 运行run.sh

    ```
    cd docker-compose-starter
    ./run.sh
    ```
    进入交互菜单，选择 ```a``` -> ```b``` ，启动所有服务。（第一次运行会经历漫长的拉取镜像过程，请耐心等候。）

    ![首次启动](https://gitee.com/philiphuang/docker-compose-starter/raw/master/docs/first-start.png)

    当你看到下面的文字，你已经喜提一个三层结构的应用，nginx + (tomcat，srpingboot) + mysql

    ![首次启动完成](https://gitee.com/philiphuang/docker-compose-starter/raw/master/docs/done-first-start.png)

3. 打开浏览器访问宿主机，例如：[http://localhost/](http://localhost/)

    ![主页](https://gitee.com/philiphuang/docker-compose-starter/raw/master/docs/home-page.png)

4. 最后，关掉所有服务（交互菜单选```a``` -> ```c```），去./code目录下替换你的jar和war，重新执行第二步，你就可以把你的应用跑起来。

## 按需剪裁

DC-Starter开箱时已包含一个三层结构的Java应用，你可以以此为骨架，修改成你自己的应用。或者在家里的NAS跑个jellyfin，aria2，也是挺方便的。

### 运行阶段

我们倒着来，先看看运行阶段DC-Starter有什么功能。

DC-Starter对Docker-Compose的命令进行封装，已经包含基本的启动，关闭，查看日志等基本功能，如果不够用的话，还可以加入你的自定义脚本。

老规矩，所有操作都从 ```./run.sh``` 开始

![主菜单](https://gitee.com/philiphuang/docker-compose-starter/raw/master/docs/main-menu.png)

    a) 对所有服务执行：启动，关闭，重启

    b) 对单个服务执行：启动，关闭，重启

    c) 查看日志

    d) 进入单个容器的shell

    e) 进入mysql容器的mysql命令行

    f) 查看服务的运行状态，包括启动时间，端口和IP等信息

    g) 用户可以加入自己的脚本，例如备份，还原，可添加多个

    h) 退出，或者返回上一级菜单

### 配置阶段

无论简单还是复杂的应用，都离不开下面基本步骤：

 1. 修改.env文件
 2. 注入docker-compose.yml
 3. 注入jar，html文件
 4. 修改run.sh

### 修改.env
 1. .env保存了最核心的配置信息；
 2. 宿主机上如果运行了多套应用，每套应用的PROJECT_NAME和IP_RANGE不能重复；
 3. 记得把密码改掉；
 4. 可以全项目搜索"TODO"，找到需要改动的地方。

### 修改docker-compose.yml
 1. 服务名（service name）要和CONTAINER_LIST_TEXT的值对应上。

### 拷贝文件
 1. DC-Starter设计的起因是方便开发人员调试代码，因此代码不是打包在镜像里面，而是映射到容器里面；同时也预置了一些目录，对配置文件、代码进行了分离。当然，代码打包到镜像里面也是不拒绝的，而且更适合生产环境。
     1. code目录：运行代码，例如jar，war，也接受其他语言的代码，记得在docker-compose.yml文件中映射到容器里面；
     2. config目录：存放各个服务的配置文件；
     3. mysql的配置文件位于./config/mysql_config，初始化数据目录位于./config/mysql_init，参看docker hub的mysql镜像的说明，https://hub.docker.com/__/mysql (请连接中两个下划线的一个）
     4. nginx的配置文件位于./config/nginx；
     5. data目录存放运行过程中产生的业务数据，例如mysql的文件和用户上传的文件，可统一备份此目录下的文件；
     6. logs目录存放日志，可定时清理。

 2. 修改run.sh
    1. 可以在run.sh里面需要加入自定义的shell脚本，可以参考func7和func8两个函数，自定义函数从7开始自增；
     2. 如果服务是由多个yml文件组成，需修改DCC_COMMAND变量；
     3. 如果需要通过不同的脚本提供不同的服务目标，你可以编写针对特定业务流程的代码，例如还原数据是低频操作，不放在run.sh里面，具体实现可参考restore.sh，运行方式是```./run.sh restore.sh```。

## 其他说明

1. 如果你需要用DC-Starter管理多个项目，一个方法是把目录复制多一份，另外一个方法是在docker-compose.yml同级建porject1、project2目录，把code，config在project1、project2都复制一份；
2. config_repositry目录存放了一些常用的配置模板，如redis，可按需食用。

## 使用案例
 1. 运行rrshare容器：[Github](https://github.com/philiphuang/rrshare)，[Gitee](https://gitee.com/philiphuang/rrshare)
 2. 运行jellyfin，Jellyfin是一个开源的媒体管理和播放系统，Emby和Plex的免费替代品。[Github](https://github.com/philiphuang/jellyfin)，[Gitee](https://gitee.com/philiphuang/jellyfin)
