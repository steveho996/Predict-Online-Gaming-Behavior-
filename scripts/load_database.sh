#!/usr/bin/env bash
# DATABASE_URL must be provided securely by the caller; never commit it.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DATABASE_URL:?Set DATABASE_URL to your PostgreSQL connection string}"
psql -X --dbname="$DATABASE_URL" --set ON_ERROR_STOP=1 --single-transaction --file sql/01_schema_and_load.sql
psql -X --dbname="$DATABASE_URL" --set ON_ERROR_STOP=1 --file sql/02_validation.sql
