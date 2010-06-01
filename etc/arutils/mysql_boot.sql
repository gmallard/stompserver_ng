--
--
-- This might depend on your mysql set up:
--
-- * mysql -u root -p mysql < mysql_boot.sql
--
CREATE USER 'ssng'@'localhost' IDENTIFIED BY 'xxxxxxxx';
GRANT ALL PRIVILEGES ON ssng_dev.* TO 'ssng'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ssng_dev.* TO 'ssng'@'%' WITH GRANT OPTION;
--
CREATE DATABASE ssng_dev;

