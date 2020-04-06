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
    1. 命令行控制台，省去重复敲打docker-compose命令的负担
    1. 预置的功能，如启动、关闭、重启容器、查看容器日志，进入容器的shell
    1. 可运行用户自定义脚本，如备份还原文件，

  - 目录模板
    1. 项目的文件，可以放在根目录下
      1. 如果包含单一项目，也按照文件的用途分目录，如代码，配置，需要备份的文件，可丢弃的文件来管理
      1. 如果需要包含多个项目，可以按项目维度分目录（project1~n）
    1. 项目提供了典型的启动脚本（./run.sh），你也可以根据不同管理目标，按需扩展脚本(./run.sh restore.sh)，甚至只管理其中一部分容器(restore.yml)。
