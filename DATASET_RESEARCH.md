# TrafficTwin — UTD19 Dataset Research

**Research:** 14 October 2026  
**Documentation update:** 15 October 2026  
**Status:** Data discovery and initial quality analysis completed. ML-ready dataset has **not** yet been built.

## 1. Source and download verification

- Original dataset website: https://utd19.ethz.ch/ (the request-by-email download link was not arriving for either project partner).
- Official ETH Zurich Research Collection alternative: https://www.research-collection.ethz.ch/entities/researchdata/bfb14ee7-82c8-4357-a293-3bf18d8f93f9
- Downloaded file: `~/Datasets/utd19_u.csv`
- Exact size: **6,978,610,359 bytes** (~6.98 GB decimal; ~6.50 GiB).
- `wc -l`: **134,380,372** lines, including the header = **134,380,371 data records**. This matches an independently reported record count for this file.
- CSV header: `day,interval,detid,flow,occ,error,city,speed`.
- `file`, `head`, and `tail` checks looked normal, and DuckDB successfully scanned the full file. **No authoritative SHA-256 checksum has been compared**, so byte-for-byte integrity has not been proved.
- **39 distinct cities** were found in this particular CSV (the broader UTD19 site has advertised 40; Tokyo was absent from this file).
- The ETH collection also provides small **detector metadata**, **road-link geometry**, and a **manual**. Download these as well to interpret the IDs, locations, road network, units, and quality flags. They had not been confirmed downloaded in this conversation.

## 2. Main measurement file: column dictionary

**Authoritative source:** [ETH Zurich UTD19 documentation (August 2020)](https://www.research-collection.ethz.ch/server/api/core/bitstreams/876608ef-7974-457a-8848-b8e1c48ef33f/content), section **6–7, "Traffic measurements"** (printed p. 5; PDF p. 8). The manual calls the data file `UTD19.csv`, while the locally downloaded file analyzed in this project is `utd19_u.csv`; the eight-column schema below was also confirmed directly from the local CSV. The manual's broader `UTD19.csv` row count must **not** be used as a checksum for this `_u.csv` variant.

**Unit of observation:** one stationary detector's measurement for one time interval. **Not** a row per vehicle, a vehicle trajectory, a traffic-light phase, or an intersection-wide queue observation. The raw file's actual column order is `day,interval,detid,flow,occ,error,city,speed`.

| Column | Expected representation | Definition and units | Example / practical interpretation |
|---|---|---|---|
| `day` | Date (`YYYY-MM-DD`) | Calendar date of recording | `2015-11-01` = 1 November 2015 |
| `interval` | Integer | **Start** of the recording interval, in **seconds after midnight** on `day` | `86040` = 23:54:00; Luzern's typical successive values differ by **180 seconds (3 min)** |
| `detid` | String | Identifier of the stationary detector; join key to detector metadata | `K8D20` (Zurich); `ig11FD116_D35` (Luzern). Include city in joins unless ID uniqueness across cities is established. |
| `flow` | Numeric, nullable in general | Traffic flow, standardized to **vehicles per hour per lane** (`veh/h/lane`) for that detector, even if it spans several lanes | `200` denotes a rate of 200 veh/h/lane; over a 3-minute interval this corresponds to 10 vehicles/lane **at that rate**, not 200 vehicles observed in 3 min |
| `occ` | Numeric, nullable | Detector **occupancy**, i.e. fraction of observation time during which the detector was occupied; a proxy for traffic state, **not** literal percentage of roadway covered or exact queue length | `0.028333334` ≈ **2.83%** occupancy; `0.25` ≈ **25%** |
| `error` | Nullable integer-like field | An *identified or reported measurement error* is indicated by a **non-missing** value according to the manual. **The manual does not define separate semantics for numeric values `0` and `1`.** | The local file contains `NULL`, `0`, and `1` in different cities. Preserve the original flag; do not assume `0=valid`, or that every non-null row must be irreversibly discarded. |
| `city` | String | City associated with the measurement | `luzern`, `hamburg`, `zurich` |
| `speed` | Numeric, nullable | Average detector-measured traffic speed during the interval, in **km/h** | A blank field = missing data. `speed` is **100% missing** in the *locally tested* Luzern, Hamburg, and London subsets; do not generalize that finding to every city. |

### Worked example from the actual download

```csv
day,interval,detid,flow,occ,error,city,speed
2015-11-01,86040,K8D20,200,0.028333334,0,zurich,
```

- **When / where:** Zurich, **2015-11-01 23:54**, detector `K8D20`.
- **Flow:** an hourly-equivalent rate of **200 vehicles/hour/lane**. If its sampling interval were 3 minutes, this rate would be equivalent to **10 vehicles/lane in that interval**; do not interpret the `flow` field as a raw vehicle count.
- **Occupancy:** approximately **2.83%** of the observation interval.
- **Speed:** missing, not zero.
- **Error:** the non-null value `0` is present, but the documentation does **not** provide a `0`-versus-`1` interpretation. Treat its quality status as requiring verification.

### How to use these columns for TrafficTwin

- **Forecast target:** first predict future **`flow` (veh/h/lane)** at horizons of **15 and 30 minutes**, retaining the unit in metrics and visualizations.
- **Candidate features:** historical `flow`, `occ` where trustworthy, detector ID, calendar/time features derived from `day + interval`, and later detector/road metadata. Do **not** use a future reading to construct the features of an earlier prediction.
- **Timestamp reconstruction:** `timestamp = CAST(day AS TIMESTAMP) + interval * INTERVAL '1 second'`. Confirm time-zone and daylight-saving assumptions before interpreting this as a global timestamp.
- **Missingness:** blank `speed` (or `occ` elsewhere) means unavailable, **not** zero. Missing *rows* must also be represented explicitly when creating fixed-step sequences; dropping flagged rows must not compress time.
- **Error values:** the existing 79-detector selection treats `error IS NULL AND flow IS NOT NULL` as **provisionally unflagged**, not definitively validated. Document and reassess this rule before final training and model reporting.
- **Sensor coverage:** the measure describes a detector/lane or lanes, not the whole intersection; using it as SUMO arrival demand will require calibration, direction/lane mapping, and independent evaluation.

## 3. Companion files: detector locations and road geometry

**Source:** same [official manual](https://www.research-collection.ethz.ch/server/api/core/bitstreams/876608ef-7974-457a-8848-b8e1c48ef33f/content), sections **2–5** (printed pp. 3–4; PDF pp. 6–7). These definitions describe separate files offered by ETH, **not extra columns in `utd19_u.csv`**. Download status remains unconfirmed.

### `detectors.csv` — one row per detector (11 columns in the manual)

| Column | Meaning |
|---|---|
| `detid` | Detector ID; connects to `utd19_u.csv` observations |
| `citycode` | City identifier/name; match to the measurement file's `city` |
| `length` | Length of monitored lane, **km** |
| `pos` | Distance along road to downstream signal / major intersection, **km**; **not** latitude/longitude |
| `long`, `lat` | Detector longitude and latitude |
| `lanes` | Number of lanes monitored |
| `linkid` | Identifier of the monitored lane/road link; may be missing for unmatched detectors |
| `fclass` | Functional road class from OpenStreetMap |
| `road` | Road name |
| `limit` | Speed limit where available |

**Join guidance:** conceptually join measurements to detectors by `detid` (and matching city if needed). Check for duplicated IDs and normalized city naming before applying a many-to-one join; otherwise a bad join can silently multiply rows.

### `links.csv` — ordered coordinates along monitored links (7 columns)

| Column | Meaning |
|---|---|
| `citycode` | City identifier/name |
| `linkid` | Road link/lane identifier; connects to `detectors.csv` |
| `order` | Position of a waypoint in traffic-flow direction |
| `piece` | Spatial feature number for the link |
| `group` | Group number within that spatial feature |
| `long`, `lat` | Longitude and latitude of the waypoint |

**Join guidance:** `links.csv` generally contains multiple waypoint rows per link. Join on **`citycode` + `linkid`** for geometry construction, but **do not** directly join all geometry rows to each traffic measurement or you will duplicate measurements. Aggregate the ordered waypoints into a line first.

## 4. City-level exploration

DuckDB grouped the full CSV by `city`, measured row counts and unique detectors, and identified date ranges. Relevant candidates:

| City | Records | Detectors | Distinct observed days | Date range |
|---|---:|---:|---:|---|
| London | 34,397,322 | 5,719 | 23 | 2015-05-15 to 2016-05-22 |
| Luzern | 26,878,297 | 158 | 365 | 2015-01-01 to 2015-12-31 |
| Hamburg | 20,415,435 | 418 | 105 | 2016-08-27 to 2016-12-09 |
| Madrid | 5,070,083 | 1,116 | Not measured separately | 2016-08-29 to 2017-11-11 |
| Zurich | 3,425,002 | 1,020 | Not measured separately | 2015-10-26 to 2015-11-01 |
| Torino | 2,080,768 | 399 | Not measured separately | 2016-09-26 to 2016-10-16 |

For London, Hamburg, and Luzern, `flow` was non-null in 100% of records; `occ` was non-null in 100% for London and Luzern and 99.34% for Hamburg; **`speed` was null in all their records**. This CSV is useful for **traffic-flow forecasting**, not directly for computer vision, traffic signal timings, or obtaining all variables needed to simulate signal control.

## 5. Important `error`-field findings / caveat

| City | `error IS NULL` | `error = 0` | `error = 1` |
|---|---:|---:|---:|
| Luzern | 17,812,356 | 0 | 9,065,941 |
| Hamburg | 10,507,107 | 0 | 9,908,328 |
| London | 0 | 22,163,317 | 12,234,005 |

**Working assumption used for the quality queries:** `error IS NULL AND flow IS NOT NULL` defines an *unflagged* flow observation. The official manual says a non-missing `error` value indicates an identified or reported error, but **does not document separate numeric meanings for `0` and `1`**. Therefore, the meaning and reliability of the two numeric codes remain unresolved, even after consulting the manual. Do **not** automatically conclude that all London records are unusable merely because `error` is non-null, and do **not** irreversibly delete flagged observations.

## 6. Luzern quality analysis

A complete city-specific Parquet copy was successfully created:

`~/Datasets/luzern_raw.parquet`

This preserves **all 26,878,297 Luzern records**, including flagged readings. The following findings came from DuckDB queries on it:

- **158** total detectors.
- **140** detectors with at least one observation meeting the provisional `error IS NULL` rule.
- **105** detectors with observations meeting that rule on **300+ distinct days**.
- Median count of days containing at least one such observation: **358 days** per detector.
- **56,079 detector-days** in total (distinct detector + day groups).
- Average **479.3 raw records per detector-day**, close to 480 samples/day expected at **three-minute intervals**.
- **59.6% of detector-days** had **400 or more distinct unflagged time intervals**.
- Only **16 duplicate detector/day/interval observations** were counted across the city's raw file. These should still be resolved before constructing a regular time series.
- The top 20 sensors each had **365 observed days**, **359–360 days with 400+ distinct unflagged intervals**, and roughly **425–454 average unflagged intervals/day**. Example top detector: `ig11FD116_D35`, 360 high-quality days and average 445.1 clean intervals/day.

**Caveat:** Having 400 valid intervals in a day does not mean they are consecutive. Time gaps, sequence lengths, and temporal distribution still need verification.

## 7. Selected broader cohort: 79 reliable detectors

We evaluated the rule:

> A detector is eligible if it has **at least 250 days**, each containing **at least 400 distinct intervals** with `error IS NULL AND flow IS NOT NULL`.

DuckDB returned:

| Metric | Exact result |
|---|---:|
| Eligible detectors | **79** |
| All records from those detectors (including flagged) | **13,818,910** |
| Provisional unflagged records | **12,109,307** |
| Unflagged share of selected records | **87.6%** |

At 79 detectors × 365 days × 480 3-minute slots/day, there are **13,840,800 theoretical detector-time slots** for a full year. Raw record count is near that total, but **count/expected slots is not a verified coverage rate** because duplicates, gaps, and flags exist.

The earlier proposal of **20 sensors** was a convenient prototype subset, **not** a requirement or the preferred cap. The proposed working cohort for broader exploratory forecasting is **79 detectors**. Approximately **12.1 million provisional unflagged measurements** is sufficient in volume for initial forecasting experiments, but adjacent readings are highly correlated, so it is not equivalent to 12.1 million independent training cases.

## 8. Decisions and next steps

**Provisional decision:** Use **Luzern 2015** for the first TrafficTwin traffic-flow forecasting baseline; keep Hamburg as a potential second-city generalization test. The project has **not yet** trained a model or created a final ML-ready dataset. Do not treat city selection as proof of predictive accuracy or geographic representativeness.

1. **Download detector metadata, road links, and official manual.** Check actual detector locations/connectivity and the exact meaning of the `error` field. The 79 sensors' geographic distribution has not yet been checked.
2. **Keep the full Luzern raw Parquet immutable.** Create a *new*, versioned, processed output. Retain error flags and provenance.
3. **For final evaluation, select sensors using only training-period data** (the current 79 were selected using all of 2015, which can create future-availability selection bias).
4. **Construct regular three-minute time series**, resolve duplicate detector/time rows, detect missing intervals and long gaps, and decide how to handle flagged/invalid observations without collapsing time.
5. **Do exploratory analysis** by detector, hour, day of week, and season; check suspicious values, time-zone/daylight-saving handling, and sensor coverage.
6. **Split chronologically** into training, validation, and test. Avoid random splits that leak temporal information.
7. **Start with simple baselines** (persistence and seasonal/historical average); evaluate 15- and 30-minute flow forecasting, then try gradient boosting or GRU/LSTM models if justified.
8. **Keep forecasting and simulation conceptually separate:** UTD19 is historical stationary-sensor data. It is not a labeled vision dataset, a signal-phase log, or a ready-to-run SUMO network. Traffic-light optimization claims require separately designed, validated simulation experiments.

**Current status:** Dataset downloaded and substantially characterized; Luzern raw Parquet created; promising 79-detector cohort identified **by query only**; **no final 79-detector modeling file, aligned time-series data, or trained model created yet**.
