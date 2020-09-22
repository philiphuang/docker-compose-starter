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
