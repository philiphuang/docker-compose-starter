# this file is a placeholder, please refer template file from ../mysql_init_temlate

DROP USER IF EXISTS 'dcuser'@'%';
CREATE USER 'dcuser'@'%' IDENTIFIED BY 'got2changthispwd';
GRANT ALL PRIVILEGES ON *.* TO 'dcuser'@'%' IDENTIFIED BY 'got2changthispwd';
GRANT ALL PRIVILEGES ON *.* TO 'dcuser'@'localhost' IDENTIFIED BY 'got2changthispwd';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'got2changthispwd';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'got2changthispwd';

FLUSH PRIVILEGES;