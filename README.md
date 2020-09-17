# docker-launcher
Docker Compose project template, including launching scripts and project template.
  - launching scripts
    1. easy-to-use menu style management, no need to remember docker-compose commands.
    1. build-in management script, like start/stop containers or entering docker shell.
    1. customized script, like backup/restore data.

  - project template
    1. You could manage single project or multiple projects all-in-one folder
      1. for single project, you may arrange folders in different purpose, such as code, config, backup, temp.
      1. for multiple projects, you may arrange folder by project name.
    1. you could use the default run.sh to manage your project, or extend new script for different management purpose, such as(./run.sh restore.sh) for restoring files, within a subset of containers(defined in extra restore.yml).

Docker Compose项目模板，包含启动脚本和目录模板。
  - 启动脚本
    1. 命令行控制台，省去重复键入docker-compose命令的负担
    1. 预置启动、关闭、重启容器、查看容器日志，进入容器的shell等命令行
    1. 可运行用户自定义脚本，如备份还原文件，
    1. 项目提供了典型的启动脚本（./run.sh），你也可以根据不同管理目标，按需扩展脚本(运行```./run.sh restore.sh```)，或者只管理其中一部分容器(参考restore.yml)。

  - 目录模板
    1. 预置nginx、tomcat、springboot、mysql，redis等容器模板，开箱即用。
    1. 目录布局合理，代码，配置文件，数据，业务文件，日志文件分开存放，方便进行全量备份和全量恢复
      1. 支持单一项目，也支持多项目很合部署
      1. 可对配置文件，生产数据，生产过程产生的客户文件进行备份

![主菜单](./docs/main-menu.png)
  - 基本功能：

    a) 对本项目所有容器进行管理，包括启动，关闭，重启

    b) 对单个容器进行管理，包括启动，关闭，重启

    c) 查看单个容器日志

    d) 进入单个容器的shell

    e) 进入mysql容器的mysql cli

    f) 查看个容器的运行状态，包括启动时间，端口和IP等信息

    g) 自定义脚本，可添加多个

    h) 退出，如果进入了子菜单，则返回上一级菜单
