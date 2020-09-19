#!/bin/bash

source /postexecute/utils/check-env.sh

check_env "mysqlimport" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST" "MYSQL_DATABASE"

DUMP_PATH_FULL=$VOLUMERIZE_SOURCE/${MYSQL_DUMP_PATH}
SQL_FILENAME_LN=${DUMP_PATH_FULL}/${MYSQL_DATABASE// /_}.sql.gz

echo "mysql import starts"
gunzip < ${SQL_FILENAME_LN} | mysql -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h${MYSQL_HOST}
echo "Import done"