### Set default
PG_DATABASE=postgres
PG_USER=postgres

### pg connect
- make console-pg**
- psql -U postgres
### show all Dbs
- select * from pg_database;
### create or drop
- CREATE DATABASE ${POSTGRES_DB};
- DROP DATABASE IF EXISTS ${POSTGRES_DB};
### show all users
- \du+
### change password
- \password
### exit
- \q
