#!/bin/bash

File='en_GB-general'
DBUser='root'
DBPassword='omu2tbdf'

FILES=~/CofA/*
for f in $FILES
do
	if [ ! -d "$f" ]; then
		FileName=`basename $f`
		File="${FileName%.*}"
		echo $File
		mysql -u$DBUser -p$DBPassword -e 'DROP DATABASE IF EXISTS chartcreate'

		mysql -u$DBUser -p$DBPassword -e 'CREATE DATABASE chartcreate'

		sed -i 's/TYPE=MyISAM/ENGINE=InnoDB/g' ~/CofA/$File.sql
		sed -i 's/TYPE=InnoDB/ENGINE=InnoDB/g' ~/CofA/$File.sql
		sed -i 's/InnoDB/InnoDB DEFAULT CHARSET=utf8/g' ~/CofA/$File.sql
		mysql -u$DBUser -p$DBPassword chartcreate < ~/CofA/$File.sql

		mysql -u$DBUser -p$DBPassword chartcreate -e "CREATE TABLE accountsection (sectionid int(11) NOT NULL DEFAULT '0',sectionname text NOT NULL,PRIMARY KEY (sectionid)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
		mysql -u$DBUser -p$DBPassword chartcreate -e "INSERT INTO accountsection (SELECT (cid*10),class_name FROM 0_chart_class)"

		mysql -u$DBUser -p$DBPassword chartcreate -e "CREATE TABLE accountgroups (groupname char(30) NOT NULL DEFAULT '',sectioninaccounts int(11) NOT NULL DEFAULT '0',pandl tinyint(4) NOT NULL DEFAULT '1',sequenceintb smallint(6) NOT NULL DEFAULT '0',parentgroupname varchar(30) NOT NULL,PRIMARY KEY (groupname),KEY SequenceInTB (sequenceintb),KEY sectioninaccounts (sectioninaccounts),KEY parentgroupname (parentgroupname)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
		mysql -u$DBUser -p$DBPassword chartcreate -e "INSERT INTO accountgroups (SELECT name,(class_id*10),NOT(balance_sheet),(id*1000),'' FROM 0_chart_types INNER JOIN 0_chart_class ON 0_chart_types.class_id=0_chart_class.cid)"

		mysql -u$DBUser -p$DBPassword chartcreate -e "CREATE TABLE chartmaster (accountcode varchar(20) NOT NULL DEFAULT '0',accountname char(50) NOT NULL DEFAULT '',group_ char(30) NOT NULL DEFAULT '',PRIMARY KEY (accountcode)) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
		mysql -u$DBUser -p$DBPassword chartcreate -e "INSERT INTO chartmaster (SELECT account_code,account_name,name FROM 0_chart_master INNER JOIN 0_chart_types ON 0_chart_master.account_type=0_chart_types.id)"

		echo '<?php' > ~/CofA/updates/$File.php
		mysql -u$DBUser -p$DBPassword chartcreate -N -e "SELECT CONCAT('InsertRecord(',CHAR(39),'accountsection', CHAR(39), ',array(',CHAR(39),'sectionid',CHAR(39),'),array(',sectionid,'),array(',CHAR(39),'sectionid',CHAR(39),',',CHAR(39),'sectionname',CHAR(39),'),array(',sectionid,',',CHAR(39),sectionname,CHAR(39),'));') FROM accountsection" >> ~/CofA/updates/$File.php
		mysql -u$DBUser -p$DBPassword chartcreate -N -e "SELECT CONCAT('InsertRecord(',CHAR(39),'accountgroups', CHAR(39), ',array(',CHAR(39),'groupname',CHAR(39),'),array(',CHAR(39),groupname,CHAR(39),'),array(',CHAR(39),'groupname',CHAR(39),',',CHAR(39),'sectioninaccounts',CHAR(39),',',CHAR(39),'pandl',CHAR(39),',',CHAR(39),'sequenceintb',CHAR(39),',',CHAR(39),'parentgroupname',CHAR(39),'),array(',CHAR(39),groupname,CHAR(39),',',CHAR(39),sectioninaccounts,CHAR(39),',',CHAR(39),pandl,CHAR(39),',',CHAR(39),sequenceintb,CHAR(39),',',CHAR(39),parentgroupname,CHAR(39),'));') FROM accountgroups" >> ~/CofA/updates/$File.php
		mysql -u$DBUser -p$DBPassword chartcreate -N -e "SELECT CONCAT('InsertRecord(',CHAR(39),'chartmaster', CHAR(39), ',array(',CHAR(39),'accountcode',CHAR(39),'),array(',CHAR(39),accountcode,CHAR(39),'),array(',CHAR(39),'accountcode',CHAR(39),',',CHAR(39),'accountname',CHAR(39),',',CHAR(39),'group_',CHAR(39),'),array(',CHAR(39),accountcode,CHAR(39),',',CHAR(39),accountname,CHAR(39),',',CHAR(39),group_,CHAR(39),'));') FROM chartmaster" >> ~/CofA/updates/$File.php
		echo -n '?>' >> ~/CofA/updates/$File.php
	fi
done
