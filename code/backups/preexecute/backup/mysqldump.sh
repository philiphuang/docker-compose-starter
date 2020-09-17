#!/bin/bash
source /preexecute/utils/check-env.sh

check_env "Mysqldump" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST" "MYSQL_DATABASE" "MYSQL_DUMP_PATH"

set -x

DUMP_PATH_FULL=$VOLUMERIZE_SOURCE/${MYSQL_DUMP_PATH}
echo "Creating $DUMP_PATH_FULL folder if not exists"
mkdir -p $DUMP_PATH_FULL

SQL_FILENAME=${DUMP_PATH_FULL}/${MYSQL_DATABASE// /_}_`date +%Y-%m-%d`.sql.gz
SQL_FILENAME_LN=${DUMP_PATH_FULL}/${MYSQL_DATABASE// /_}.sql.gz

# SQL_CMD=${MYSQL_DATABASE// /\',\'}
# SQL_CMD="SELECT ROUND(SUM(data_length * 0.8), 0) FROM information_schema.TABLES WHERE table_schema in ('${SQL_CMD}');"

# Based on this answer https://stackoverflow.com/a/32361604
# SIZE_BYTES=$(mysql --skip-column-names -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} mysql -e "${SQL_CMD}")

# echo "mysqldump and gzip starts (Progress is aproximated)"

# ${MYSQL_DATABASE}包含多个数据库，数据库与数据库之间有空格，如果写成"${MYSQL_DATABASE}"，值两侧会出现单引号，如果写成${MYSQL_DATABASE}，值的两侧则不出现单引号
# 修改依据 https://confluence.atlassian.com/confkb/mysqlsyntaxerrorexception-row-size-too-large-658735905.html
mysqldump --databases ${MYSQL_DATABASE} --max_allowed_packet=512M --single-transaction --add-drop-database --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" --host="${MYSQL_HOST}" | gzip -c > ${SQL_FILENAME}
ln -s -f ${SQL_FILENAME} ${SQL_FILENAME_LN}
set +x