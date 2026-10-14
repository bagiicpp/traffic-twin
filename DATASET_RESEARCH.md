# TrafficTwin — UTD19 Dataset Research Summary
**Date:** October 14, 2026

## 1. Dataset acquisition and verification

We obtained UTD19 from the official [ETH Zurich Research Collection](https://www.research-collection.ethz.ch/entities/researchdata/bfb14ee7-82c8-4357-a293-3bf18d8f93f9) because the original website wasn't delivering download links.

- File: `~/Datasets/utd19_u.csv`
- Size: **6,978,610,359 bytes (~6.98 GB)**
- Records: **134,380,371** (excluding header)
- Cities present: **39**
- Columns: `day, interval, detid, flow, occ, error, city, speed`
- File passed basic format, record-count, and full DuckDB parsing checks. No authoritative checksum comparison has been performed.

**Still needed:** Download the detector metadata, road-link geometry, and official dataset manual.

## 2. City analysis

We analyzed all 39 cities and shortlisted three:

| City | Measurements | Detectors | Observed days |
|---|---:|---:|---:|
| Luzern | 26,878,297 | 158 | 365 |
| Hamburg | 20,415,435 | 418 | 105 |
| London | 34,397,322 | 5,719 | 23 |

**Provisional selection: Luzern (2015).**

Luzern has an entire year of recorded days, dense three-minute measurements, and substantial unflagged traffic-flow observations.

All three shortlisted cities have flow measurements, but no populated speed measurements in this particular CSV.

## 3. Luzern data-quality findings

Created `~/Datasets/luzern_raw.parquet`, containing all 26.88 million Luzern records, including flagged observations.

Initial analysis revealed:

- 158 total detectors.
- 140 detectors with at least some provisionally unflagged measurements.
- 105 detectors with unflagged measurements on at least 300 distinct days.
- Median of 358 days containing unflagged measurements per detector.
- 56,079 detector-days.
- Average 479.3 raw records per detector-day, against an expected 480 at three-minute intervals.
- 59.6% of detector-days contain at least 400 distinct unflagged intervals.
- Only 16 duplicate detector/day/interval records were detected.

**Important caveat:** Our current quality checks treat `error IS NULL AND flow IS NOT NULL` as unflagged. We must confirm the official semantics of the `error` field before permanently excluding observations.

## 4. Final candidate-detector selection

We applied the following provisional eligibility rule:

A detector must have at least **250 days containing 400 or more distinct unflagged three-minute intervals**.

Results:

| Metric | Value |
|---|---:|
| Eligible detectors | **79** |
| Total measurements from eligible detectors | **13,818,910** |
| Provisionally unflagged measurements | **12,109,307** |
| Unflagged share | **87.6%** |

This is a substantial dataset for initial traffic-flow forecasting. We decided not to limit the main experiment to the original 20-detector prototype idea.

**Note:** The 79 detectors were selected using the full year. For final model evaluation, detector eligibility must be determined using training-period information only, avoiding future-data selection bias.

## 5. Planned ML pipeline

1. Join detector metadata and inspect geographical coverage.
2. Preserve original records and error flags.
3. Construct continuous three-minute time series.
4. Resolve duplicate timestamps, missing observations, and quality flags.
5. Perform exploratory analysis by detector, time of day, weekday, and season.
6. Use chronological training, validation, and testing splits.
7. Establish persistence and historical-average forecasting baselines.
8. Train and evaluate models forecasting traffic flow 15 and 30 minutes ahead.
9. Explore LightGBM, GRU, LSTM, or spatiotemporal architectures where justified.
10. Investigate integration with SUMO for simulated traffic-control decisions.

## 6. Current project status

**Completed:** Download verification, city comparison, initial quality analysis, Luzern Parquet extraction, and identification of a promising 79-detector cohort.

**Not completed:** Metadata integration, final cohort extraction, fully aligned time-series preparation, model training, evaluation, or SUMO integration.

**Next objective:** Build a reproducible preprocessing pipeline for Luzern, starting from the raw Parquet file, while ensuring all data-cleaning and modeling decisions can be justified and repeated.
