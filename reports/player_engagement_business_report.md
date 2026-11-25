# Online Gaming Player Engagement and Retention Analysis

Synthetic-data engagement analysis and retention experiment design.

## Executive summary

The saved PostgreSQL analysis covers 40,034 unique player snapshots. High-engagement players average 14.25 weekly sessions versus 4.53 for Low-engagement players. These are descriptive associations, not evidence of causality or future churn. Results summarize the saved SQL run, not a fresh database extract.

## Engagement baseline

| Engagement | Players | Share | Mean weekly sessions | Mean session minutes | Mean recorded hours | Purchase participation |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Low | 10,324 | 25.79% | 4.53 | 66.88 | 12.10 | 19.73% |
| Medium | 19,374 | 48.39% | 9.55 | 89.86 | 11.96 | 19.98% |
| High | 10,336 | 25.82% | 14.25 | 131.92 | 12.07 | 20.65% |

## Audience definitions

- Priority 1: Low engagement, at most 4 weekly sessions, purchaser: 1,312 players.
- Priority 2: Low engagement, at most 4 weekly sessions, non-purchaser: 5,326 players.
- Priority 3: Low engagement and more than 4 weekly sessions: 3,686 players.
- High-value proxy: High engagement, purchaser, recorded playtime at or above the full-snapshot 75th percentile (17.963831138295756 hours), and at least 14 weekly sessions: 309 players.

The Low-engagement groups total 10,324 players, including 869 under-18 records requiring safeguarding review. These are analytical review audiences, not contact-ready lists or validated churn-risk rankings.

## Business implications

Investigate low-frequency and frequent-but-Low groups using additional telemetry and feedback before selecting interventions. Test suitable support with a randomized control group and predefined success measures. Small demographic differences do not justify demographic-led targeting.

## Limitations

The dataset is synthetic and cross-sectional. Engagement is not measured retention or observed churn. Purchase flags measure participation, not revenue. Recorded playtime has an ambiguous time basis and must not be silently interpreted as weekly hours. No retention uplift, revenue gain, or causal effect has been demonstrated.

Dataset: Rabie El Kharoua, Predict Online Gaming Behavior Dataset, CC BY 4.0. https://www.kaggle.com/datasets/rabieelkharoua/predict-online-gaming-behavior-dataset
