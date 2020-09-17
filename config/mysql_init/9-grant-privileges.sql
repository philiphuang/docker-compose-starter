drop user 'dctuser'@'%';
create user 'dctuser'@'%' IDENTIFIED BY 'got2changthispwd';
GRANT ALL PRIVILEGES ON *.* TO 'dctuser'@'%' IDENTIFIED BY 'got2changthispwd';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'got2changthispwd';
FLUSH PRIVILEGES;