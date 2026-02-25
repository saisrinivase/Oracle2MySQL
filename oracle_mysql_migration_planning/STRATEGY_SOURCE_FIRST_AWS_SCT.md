# Source-First Strategy (Oracle -> Aurora MySQL with AWS SCT)

This strategy is meant to avoid starting migration tooling too early.

## Objective
Build confidence in Oracle source-system behavior and dependency impact before running AWS SCT conversion for a POC schema.

## Phase 1: Source Intelligence (No migration yet)
Run:

```bash
sqlplus user/password@ORCL @/Users/saiendla/Desktop/OracletoMySQL/oracle_mysql_migration_planning/sql/run_source_intelligence_poc.sql YOUR_SCHEMA /tmp/oracle_source_intelligence 19c 8 350 40
```

What this captures:
- Source capacity profile (version/vCPU/SGA/PGA)
- Object discovery for chosen schema
- Full dependency graph (outbound + inbound + cross-schema)
- Schema complexity score and POC recommendation
- AWS SCT readiness checklist page

Primary output:
- `/tmp/oracle_source_intelligence/source_intelligence.html`

## Phase 2: POC Schema Selection Gate
Proceed only when:
- Complexity band is LOW or MEDIUM (or known bounded scope if HIGH)
- Cross-schema dependencies are approved by owners
- High-risk Oracle features are understood
- POC scope is stable and testable

## Phase 3: Install AWS SCT (after gates)
Install AWS SCT only after source intelligence is complete.

Then:
- Register Oracle source and Aurora target endpoints
- Run schema conversion report
- Review unsupported constructs and manual action items
- Produce converted DDL for POC schema

## Phase 4: Post-SCT Planning
Use SCT output + dependency/complexity findings to define:
- remediation backlog
- migration sequence
- test gates
- cutover plan

