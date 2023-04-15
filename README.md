# Heisenbug2023

## Presentation

In file Heisenbug.pdf present the lecture "How testing shows the weaknesses of the DBMS" on the conferences offline-part Heisenbug 2023 Spring (https://heisenbug.ru/offline/)

## Script slow_requests.sh
Script introduced with slow request (select count(distinct id) from users) and compared time a work the two query 
  1. select count(1) from users
  2. select count(*) from users
You can execute the script and find answer on question "What is command quicker?"  

## Script pg_qualstats.sh
Script introduced with extension pg_qualstats. How is installed, execute and work the extension.

## Remark
Scripts are checked on Centos 7 and PostgreSQL 12 version.