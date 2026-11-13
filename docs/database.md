# PostgreSQL and Neon database

The source CSV is in `data/online_gaming_behavior_dataset.csv`. The loader creates the raw staging table, normalized tables, and analysis view together in one transaction. It fails if the schemas already exist; it does not drop or overwrite existing data.

## Load

Install the PostgreSQL `psql` client and run from a terminal:

```bash
read -rsp "Neon connection string: " DATABASE_URL; echo
export DATABASE_URL
bash scripts/load_database.sh
unset DATABASE_URL
```

Use the connection string from your Neon console, including TLS settings. Do not paste credentials into GitHub, a notebook, or a tracked file.

## Schema

- `staging.raw_players`: 13 CSV fields, retained for audit and reconciliation.
- `gaming.gender`, `gaming.location`, `gaming.game_genre`: unique category lookups.
- `gaming.difficulty`: Easy, Medium, Hard.
- `gaming.engagement_level`: Low, Medium, High.
- `gaming.player`: player ID, age, and foreign keys for gender and location.
- `gaming.player_gameplay`: a one-to-one snapshot linked to player, with gameplay measures and genre, difficulty, and engagement foreign keys.
- `gaming.v_player_analysis`: joined, readable analysis view for SQL, Python, and Power BI.

The lookup IDs are surrogate keys. Difficulty and engagement IDs encode a declared order, not equal numerical distances. The player/gameplay split separates demographics from gameplay conceptually; the original unique-player table did not itself require this split to satisfy third normal form.

All normalized columns are non-null with appropriate primary keys, foreign keys, unique category names, and nonnegative numeric checks. Purchases are checked as 0/1 before conversion to boolean. Play time retains the full decimal precision supplied by the CSV.

## Validation

The import aborts on invalid constraints, duplicate player IDs, unrecognized purchase values, missing category matches, or a mismatch between the source rows and reconstructed normalized records. Run `sql/02_validation.sql` for counts and engagement distribution.

Expected source counts:

| Relation or class | Rows |
|---|---:|
| Raw, player, gameplay, and analysis view (each) | 40,034 |
| Medium engagement | 19,374 |
| High engagement | 10,336 |
| Low engagement | 10,324 |

The dataset is a player-level snapshot. Engagement classification is not a measured retention or churn outcome, and these tables do not invent activity histories, purchase transactions, or spending amounts.

## Deployment

Target: the existing Neon project `Predict Online Gaming Behavior` (`red-recipe-31102516`), `production` branch, database `neondb`. No passwords or connection URLs are stored in this repository.
