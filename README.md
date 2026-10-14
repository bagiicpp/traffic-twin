# TrafficTwin — Project Context & README

> **Status:** Concept / research planning. No implementation, dataset download, experiments, or results have been completed or verified as part of this project.
>
> **Purpose of this file:** Preserve the decisions and technical context from an initial ChatGPT discussion so that a new ChatGPT Project can continue the work without reconstructing the conversation.

## 1. Academic context

- **University/course:** University of Maribor (FERI), *Modeli in odločitveni sistemi* (MOS; Decision Making Models and Systems, course 62U013), third-year subject.
- **Team:** Blagoja Vasilev and Petar Kolev (individual contributions will need to be identifiable for grading).
- **Prior background:** This course follows an earlier Machine Learning course. The team is interested in going beyond basic ML into deep learning, computer vision, time-series forecasting, and engineering.
- **Ambition:** Create a serious, CV-worthy project with a polished demonstration. The professor reportedly selects the top three projects to present to companies at the end of the year.
- **Development style:** Prefer an actual Python codebase built with VS Code or another editor; notebooks can support EDA but should not be assumed to be the main deliverable. A React interface is an optional showcase, not an explicit academic requirement.

### Explicit MOS project requirements (from instructor instructions)

1. Choose a concrete topic and **research question** based on the availability and suitability of data.
2. **Find and combine data from multiple sources** (public datasets, APIs, self-collected data, etc.).
3. Perform **exploratory data analysis (EDA)** in Python, including visualizations.
4. Apply **machine learning** and evaluate what the data reveal.
5. **Simulate alternative decisions** using a relevant decision-making method (risk-based, multi-criteria, hierarchical, etc.), then justify a decision from results.
6. Each team member must explain their individual contribution.

The project must not be merely a neural network with an accuracy score: decision analysis is central to MOS.

## 2. Chosen direction: TrafficTwin

**Working title:** TrafficTwin — Predictive Traffic Control with Deep Learning and Multi-Criteria Decision Optimization.

**Provisional research question:**

> Can deep-learning-based traffic forecasts improve coordinated intersection control compared with fixed-time, vehicle-actuated, and non-ML adaptive traffic-signal policies, especially when traffic demand changes rapidly?

**Core concept:** Detect and count vehicles from video; predict short-term traffic demand (e.g., 5, 15, and 30 minutes ahead); use those forecasts in a simulated intersection/network; compare control decisions using measurable traffic outcomes and constraints.

**Critical clarification:** Existing smart traffic-light systems can already detect traffic and adapt signal timing, and some commercial/research systems **already forecast traffic**. Do **not** pitch TrafficTwin as the first predictive signal system. Its contribution is a carefully evaluated, student-built pipeline and comparison of prediction-assisted versus reactive decision-making.

**Another clarification:** A forecast does not itself improve traffic. The system needs a decision engine that chooses safe, feasible signal timings, and experiments showing whether outcomes improve. Predictions can be wrong; forecast uncertainty and risk should be tested.

### Conceptual pipeline

1. **Camera/video → CV:** Use object detection and tracking to estimate vehicle counts/arrival rates. Measure detection/counting error against ground truth.
2. **Traffic history + optional weather → forecasting:** Learn temporal traffic patterns; forecast incoming demand; compare basic and deep-learning baselines using chronological evaluation.
3. **Predictions → decision engine:** Select signal timing or phase allocations subject to safety/operational constraints. Consider conflicting approaches, fairness, queues, and uncertainty.
4. **SUMO simulation → outcome measurement:** Replay matched demand scenarios with alternative controllers; compare average waiting time, queue length, throughput, and robustness.
5. **Demo/dashboard:** Show video detections, forecast charts, a simulated intersection or multiple intersections, and side-by-side performance results.

## 3. Potential datasets & links

**Camera/video datasets (vision):**

- **UA-DETRAC:** https://www.albany.edu/faculty/mchang2/chang_download.html — annotated traffic videos suitable for vehicle detection/tracking/counting evaluation.
- **CityFlow:** multi-camera vehicle tracking videos; locate its current official distribution and check access/license before use. Useful for cross-camera tracking, but a relatively short recording period limits long-term forecasting.

**Historical traffic datasets (forecasting):**

- **UTD19 (ETH Zurich):** https://utd19.ethz.ch/ — traffic-detector time series across multiple cities; select a manageable subset and check field coverage and reuse terms.
- **Traffic4cast:** https://github.com/iarai/NeurIPS2021-traffic4cast — gridded historical traffic-flow/speed data; alternative particularly suited to spatial forecasting.

**Optional additional data:**

- **Open-Meteo historical weather:** https://open-meteo.com/en/docs/historical-weather-api — weather features joined by location/time where applicable; guard against using future observed weather at prediction time.

**Traffic simulation:**

- **Eclipse SUMO:** https://eclipse.dev/sumo/ — microscopic traffic simulation with signal control and realistic vehicle movements.
- **TraCI Python interface:** https://sumo.dlr.de/docs/TraCI/Interfacing_TraCI_from_Python.html — configure and test signal controllers during simulation.

### Important data limitation

UA-DETRAC/CityFlow footage and UTD19/Traffic4cast histories generally **do not represent the same intersections and time periods**. They cannot be naively merged into one physically observed sequence. Two defensible options:

- **Practical scope:** Evaluate video detection and external-data traffic forecasting separately, then use coherent simulated or calibrated demand in SUMO for controller comparisons. Be transparent about what was independently tested.
- **Stretch goal:** Obtain authorized footage and time-aligned traffic observations from the **same** intersection, or create a simulated camera/traffic setup, allowing an end-to-end evaluation. This requires more data collection and validation.

Check each dataset's licensing, redistribution, privacy, and download requirements before committing. When recording original traffic footage, take privacy rules and permissions seriously; don't retain personally identifiable imagery unnecessarily.

## 4. Candidate technology stack (not mandatory)

| Layer | Proposed tools | Purpose |
|---|---|---|
| Language / workspace | Python, VS Code, Git | Main research and implementation |
| Data analysis | pandas, NumPy, Matplotlib | Cleaning, combining, EDA |
| Computer vision | PyTorch, Ultralytics YOLO, OpenCV | Detection and video processing |
| Tracking | ByteTrack | Vehicle tracking and counts |
| Forecasting | scikit-learn, XGBoost, PyTorch (GRU/LSTM; optionally temporal CNN) | Baselines and neural forecasts |
| Simulation | Eclipse SUMO + TraCI | Controlled traffic experiments |
| Decision optimization | Custom constrained heuristics; optionally Google OR-Tools | Choose signal timing under constraints |
| API (optional) | FastAPI, Pydantic | Connect ML/simulation to interface |
| Dashboard (optional) | React, TypeScript, Vite, Recharts | Company-facing interactive demo |
| Experiment tracking (optional) | MLflow or structured CSV/JSON logs | Reproducibility |

**Do not assume that every tool is necessary.** Prioritize a scientifically solid core; add the frontend after models and simulations work.

## 5. Experimental design / proof of value

**Forecasting baselines:** Historical average / persistence, a traditional ML model (e.g., XGBoost), and one deep learning model (e.g., GRU/LSTM). Use time-ordered train/validation/test splits, not randomly mixed future observations. Evaluate with MAE/RMSE and examine performance in peak or unusual traffic.

**Control baselines inside SUMO:**

1. Fixed-time signal policy.
2. Reactively actuated policy using current simulated vehicle observations.
3. Stronger non-ML adaptive policy (if feasible).
4. TrafficTwin forecast-assisted decision policy.

**Key output metrics:** mean vehicle delay/wait time, queue length including worst cases, throughput, and performance under demand shocks / imperfect forecasts. Use comparable simulation configurations, arrival profiles, random seeds, and safety constraints across policies. Report both success and failure cases.

**MOS decision-making component:** Compare feasible alternatives on several criteria (delay, queues, throughput, fairness, and possibly emissions). Test how conclusions change with different criterion weights, risks, and forecast errors. Prevent illegal/unsafe signal phases; keep pedestrians and intergreen requirements in the simulated control design where applicable.

## 6. Suggested milestones

- **M1 — Feasibility:** Confirm dataset access, usage rights, size, and mapping to the research question. Design evaluation plan.
- **M2 — Vision:** Run pretrained detector/tracker on sample video; validate counts. Fine-tune only if evidence suggests it is needed.
- **M3 — Forecasting:** Process time series, perform EDA, create chronological baselines and a deep-learning forecast model.
- **M4 — Simulator:** Build one intersection in SUMO; implement fixed-time and reactive policies; run fair, reproducible comparisons.
- **M5 — Integration:** Add forecast-assisted policy, expand to adjacent intersections only if M4 is stable, perform ablations and risk analyses.
- **M6 — Presentation:** Optional FastAPI + React dashboard, recorded fallback demo, clear charts, limitations, and individual contributions.

**Recommended initial scope:** One simulated intersection, short-term forecasts, and three controller types. Multi-intersection coordination and reinforcement learning are **stretch goals**, not prerequisites.

## 7. What has *not* been decided

- Final dataset selections and whether downloads/access are actually convenient.
- Whether matched real video + historical detector readings can be obtained.
- Model architecture, signal-control optimizer, and success criteria.
- Whether to add reinforcement learning (potentially interesting, but higher complexity and difficult comparison).
- Whether the final demo requires real-time webcam input or only replayed prerecorded footage.
- Team responsibility split, milestones/deadline, professor's additional rubric, and hardware budget.

## 8. Guidance for future ChatGPT sessions

Continue planning **TrafficTwin** rather than restarting brainstorming. Favor deep learning, computer vision, and time-series forecasting, but consistently connect them to **real decision-making and experimental evidence** required by MOS. Challenge unjustified novelty and claims of performance. Before prescribing implementation details, verify dataset compatibility and practical scope. Aim for an ambitious, defensible, two-student, CV-worthy project with a polished company-facing presentation, without adding technology just for complexity.
