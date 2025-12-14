# ExamDB

## Architecture
![architecture](./docs/images/architecture.png)

## Database Desgin
- RBAC: [sqls/rbac](./sqls/rbac/)
- Tables and Index: [sqls/ddl](./sqls/ddl/)

## Run MVP (Minimum Viable Product)
```shell
cd docker
# clean previous mounted volumes
docker compose down -v
# start
docker compose up -d
```

Access to pgAdmin: `http://localhost:5050` (username: `admin@example.com`, password: `changeme`)
- password for the lab-pg super user: `secretpw`
