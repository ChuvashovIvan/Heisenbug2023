#!/bin/bash -e

# Ensure running a script from the root
if [ $EUID -ne 0 ]
  then echo "Please run as root!"
  exit 2
fi

PGPORT="5432"
PGDATABASE="test"

echo "Create database ${PGDATABASE}"
if [[ $( sudo -iu postgres psql -p${PGPORT} -Atqc "SELECT CASE WHEN EXISTS(SELECT * FROM pg_database WHERE datname = '${PGDATABASE}') THEN 1 ELSE 0 END" ) == "1" ]]
then
	echo "Database ${PGDATABASE} exists! Choose new name for database"
	exit
else
	sudo -iu postgres psql -p${PGPORT} -c "CREATE DATABASE ${PGDATABASE}";
fi;

echo "Create table users"
if [[ $( sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "SELECT CASE WHEN EXISTS(SELECT * FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN 1 ELSE 0 END " ) == "1" ]]
then
	echo "Table users exists. Need drop table users"
        exit
else
	sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "CREATE TABLE "users" ("id" BIGINT PRIMARY KEY, "login" VARCHAR(200) not null, "first_name" VARCHAR(200) not null, "last_name" VARCHAR(200) NOT NULL, "create_date" TIMESTAMP NOT NULL DEFAULT now())"
fi;

echo "Generate data (10000000 rowa) for table users"
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "INSERT INTO users SELECT id, RANDOM() * id, MD5(SIN(id)::TEXT), MD5(COS(id)::TEXT) FROM generate_series(1, 10000000) id;"

echo "Analyze table users"
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "ANALYZE users"
read -p "Press any key to resume ..."

echo "Explain request \"select count(distinct id) from users;\""
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "EXPLAIN SELECT count(distinct id) FROM users"
read -p "Press any key to resume ..."

echo "Explain analyze request \"select count(distinct id) from users;\""
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "EXPLAIN ANALYZE SELECT count(distinct id) FROM users"
read -p "Press any key to resume ..."

echo "Explain analyze and buffers request \"select count(distinct id) from users;\""
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "EXPLAIN (ANALYZE, BUFFERS) SELECT count(distinct id) FROM users"
read -p "Press any key to resume ..."

echo "Explain analyze and buffers request \"select count(id) from users;\""
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "EXPLAIN (ANALYZE, BUFFERS) SELECT count(id) FROM users"
read -p "Press any key to resume ..."

echo "Explain analyze and buffers request \"select count(1) from users;\""
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "EXPLAIN (ANALYZE, BUFFERS) SELECT count(1) FROM users"
read -p "Press any key to resume ..."

echo "Explain analyze and buffers request \"select count(*) from users;\""
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM users"
read -p "Press any key to resume ..."

PGBENCH=$(ps -ef -U postgres -o command | grep postmaster | awk '{print $1}'| sed 's/postmaster/pgbench/g')

echo "Test request select count(1) from users;"
echo "select count(1) from users;" | sudo -iu postgres ${PGBENCH} -p${PGPORT} -d ${PGDATABASE} -t 60 -P 60 -f -
read -p "Press any key to resume ..."

echo "Test request select count(*) from users;"
echo "select count(*) from users;" | sudo -iu postgres ${PGBENCH} -p${PGPORT} -d ${PGDATABASE} -t 60 -P 60 -f -
read -p "Press any key to resume ..."

echo "What you have result?"
echo "Finish test"
