# ExamDB

## Architecture
![architecture](./docs/images/architecture.png)

## Database Desgin
Server Configurations:
- pg configurations: [config/postgresql](./config/postgresql.conf)
- hba configurations: [config/hba](./config/pg_hba.conf)
- pgAdmin: [config/pgAdmin](./config/pgadmin/servers.json)

Schema and Roles:
- RBAC: [sqls/rbac](./sqls/rbac/)
- Tables and Index: [sqls/ddl](./sqls/ddl/)

## Run MVP (Minimum Viable Product)
```shell
git clone https://github.com/lrx0014/ExamDB.git
cd ExamDB/docker

# clean previous mounted volumes
docker compose down -v

# start
docker compose up -d
```

Access to pgAdmin: `http://localhost:5050` (username: `test-admin@test-env.com`, password: `testadminpw`)
- password for the testing super user **app_owner**: `secretpw`

## Test Cases
### 1. Test HBA rules:
```shell
# access from a normal approved location (e.g. the sysadmin_console - 172.28.0.31)
# Password for user app_owner: secretpw
# this should succeed.
docker compose exec sysadmin_console psql -h pg -U app_owner -d exam_sys -c 'select 1;'

# access from an un-approved location (unknown_console - 172.28.0.99)
# you should get an error
docker compose exec unknown_console psql -h pg -U app_owner -d exam_sys -c 'select 1;'

```
