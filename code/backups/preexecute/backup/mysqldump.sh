#!/bin/bash
source /preexecute/utils/check-env.sh

check_env "Mysqldump" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST" "MYSQL_DATABASE" "MYSQL_DUMP_PATH"

DUMP_PATH_FULL=$VOLUMERIZE_SOURCE/${MYSQL_DUMP_PATH}
echo "Creating $DUMP_PATH_FULL folder if not exists"
mkdir -p $DUMP_PATH_FULL

SQL_FILENAME=${DUMP_PATH_FULL}/${MYSQL_DATABASE// /_}_`date +%Y-%m-%d`.sql.gz
SQL_FILENAME_LN=${DUMP_PATH_FULL}/${MYSQL_DATABASE// /_}.sql.gz

# ${MYSQL_DATABASE}包含多个数据库，数据库与数据库之间有空格，如果写成"${MYSQL_DATABASE}"，值两侧会出现单引号，如果写成${MYSQL_DATABASE}，值的两侧则不出现单引号
# 修改依据 https://confluence.atlassian.com/confkb/mysqlsyntaxerrorexception-row-size-too-large-658735905.html
mysqldump --databases ${MYSQL_DATABASE} --max_allowed_packet=512M --single-transaction --add-drop-database --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" --host="${MYSQL_HOST}" | gzip -c > ${SQL_FILENAME}
ln -s -f ${SQL_FILENAME} ${SQL_FILENAME_LN}