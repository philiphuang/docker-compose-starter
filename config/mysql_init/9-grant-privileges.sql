drop user 'dcuser'@'%';
create user 'dcuser'@'%' IDENTIFIED BY 'got2changthispwd';
GRANT ALL PRIVILEGES ON *.* TO 'dcuser'@'%' IDENTIFIED BY 'got2changthispwd';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'got2changthispwd';
FLUSH PRIVILEGES;