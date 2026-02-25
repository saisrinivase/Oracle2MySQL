# Oracle Free Smoke Test (Stage 1/2/3)

This folder provides a one-command smoke test for:
- Discover
- Assess
- Plan
- Source/Target baseline profile
- MySQL target column blueprint

It runs against a local Docker Oracle Free instance and generates HTML output.

## Files
- `docker-compose.oracle-free.yml` - Oracle Free container definition
- `seed/01_seed_oracle_source.sql` - demo source objects and sample data
- `run_oracle_smoke_test.sh` - start, wait, seed, execute report toolkit
- `stop_oracle_smoke_test.sh` - stop container (optional volume purge)

## Prerequisites
- Docker Desktop
- Docker Compose v2+

## Run
```bash
cd /Users/saiendla/Desktop/OracletoMySQL/oracle_mysql_migration_planning/smoke_test
chmod +x run_oracle_smoke_test.sh stop_oracle_smoke_test.sh
./run_oracle_smoke_test.sh
```

## Optional Environment Variables
- `RESET_DB=1` - rebuild container and volume before run
- `OWNER_FILTER=OMM_%` - owner filter passed to stage toolkit
- `ORACLE_HOST_PORT=15211` - host port mapped to Oracle listener
- `ORACLE_PASSWORD=oracle123` - Oracle SYS/SYSTEM password
- `APP_USER=OMM_APP` - seeded schema user
- `APP_USER_PASSWORD=omm_app_pwd` - seeded schema user password

Example:
```bash
RESET_DB=1 OWNER_FILTER=OMM_% ./run_oracle_smoke_test.sh
```

## Stop
```bash
./stop_oracle_smoke_test.sh
```

Delete data volume too:
```bash
PURGE_DATA=1 ./stop_oracle_smoke_test.sh
```
