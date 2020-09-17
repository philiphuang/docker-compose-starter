# 移除日志
days_to_keep=${DAYS_TO_KEEP_OLD_FILE:-5}


for dir in ""${REMOVE_OLD_FILE_IN_DIR}"";
do
    find ${dir}/* -mtime +$DAYS_TO_KEEP -exec rm -rf {} \;
done;

# 移除3天以上文件备份，减少备份文件占用的空间
${VOLUMERIZE_HOME}/remove-older-than ${VOLUMERIZE_FULL_IF_OLDER_THAN} --force
