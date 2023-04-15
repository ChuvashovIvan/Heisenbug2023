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
	echo "Database ${PGDATABASE} exists! Skip command"
else
	sudo -iu postgres psql -p${PGPORT} -c "CREATE DATABASE ${PGDATABASE}";
fi

PGVERSION=$( sudo -iu postgres psql -p${PGPORT} -Atqc "select setting::int / 10000 from pg_settings where name = 'server_version_num'" )

echo "Install packages pg_qualstats_${PGVERSION}"
yum install pg_qualstats_${PGVERSION}

PGDATA=$( sudo -iu postgres psql -p${PGPORT} -Atqc "select setting from pg_settings where name = 'data_directory'" )

echo "Add extension pg_qualstats for patameters shared_preload_libraries in ${PGDATA}/postgresql.conf"
echo "shared_preload_libraries = 'pg_stat_statements, pg_qualstats'" >> ${PGDATA}/postgresql.conf

echo "Restart server PostgreSQL"
service postgresql-${PGVERSION} restart

echo "Create extension pg_qualstats in database ${PGDATABASE}"
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -Atqc "CREATE EXTENSION IF NOT EXISTS pg_qualstats"

PGBENCH=$(ps -ef -U postgres -o command | grep postmaster | awk '{print $1}'| sed 's/postmaster/pgbench/g')

echo "Init pgbench for database ${PGDATABASE}"
sudo -iu postgres ${PGBENCH} -p${PGPORT} -d ${PGDATABASE} -I dtgv -s 100 -i 

echo "Check list tables in database ${PGDATABASE}"
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -c "\dt+"

echo "Check indexes on table pgbench_accounts"
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -c "\d+ pgbench_accounts"

echo "Start test pgbench for database ${PGDATABASE}"
sudo -iu postgres ${PGBENCH} -p${PGPORT} -d ${PGDATABASE} -c 10 -j 10 -T 600

echo "Get information about indexes"
sudo -iu postgres psql -p${PGPORT} -d ${PGDATABASE} -c "
SELECT v 
FROM json_array_elements(pg_qualstats_index_advisor(min_filter => 50)->'indexes') v 
ORDER BY v::text COLLATE \"C\"
"

echo "Finish test"
