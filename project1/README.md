目录结构：
- project1：项目父目录，该项目（或模块）的所有文件归属到这里，容易迁移
- code：项目代码文件，如war、jar包，html代码等
- data：运行过程中产生的，需要持久化、备份的文件
- logs：日志文件，可丢弃
- config：基础架构的配置文件，如nginx，mysql的配置文件
    - nginx
        - project1.conf 上级项目转发到本项目的配置，放在父级nginx的/etc/nginx/conf.d/目录里面
        - nginx.conf 本项目静态和动态转发关系