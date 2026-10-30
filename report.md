# Getting to DIAG: How much does a journey really cost?

This report explores, both statistically and visually, what it really costs to commute daily to Sapienza's DIAG for lectures. When thinking about "cost", we rarely just mean money. Instead, three distinct dimensions shape the daily commute:

- **Travel time:** door-to-door duration.
- **Monetary cost:** direct expenses per trip.
- **Arrival reliability:** punctuality relative to lecture start.

Data is collected across four students labelled S1 through S4, myself being S1. It spans approximately one month of travel time (October 5 to October 30, 2026) on weekdays, totaling 20 journeys per student and 80 trips overall.

The underlying dataset records seven attributes for every one-way journey:

| Field                | Type         | Description                                                                         |
|:-------------------- |:------------:|:----------------------------------------------------------------------------------- |
| `student_id`         | Categorical  | Student identifier (`S1` for myself; `S2`, `S3`, `S4` for collegues).               |
| `date`               | Temporal     | Date of trip.                                                                       |
| `mode`               | Categorical  | Transport mode chosen (`Bicycle`, `Public transport`, `Car`, `Walk`).               |
| `distance_km`        | Quantitative | One-way distance covered in kilometers.                                             |
| `duration_min`       | Quantitative | Door-to-door trip time in minutes.                                                  |
| `cost_eur`           | Quantitative | Direct out-of-pocket monetary cost in Euro.                                         |
| `arrival_margin_min` | Quantitative | Required arrival time minus actual arrival time (positive = early, late otherwise). |

## 1. Individual Trip Analysis

To begin, let's explore my own commute data as Student S1. Living roughly 11.5 km away from DIAG, I alternate between two modes: I cycle whenever suitable, and take public transport otherwise.

Knowing my routine, I ask myself three questions:

- Bicycling is free, but how much do I actually spend when taking public transit?
- On average, what is the door-to-door duration of both means, and which one gets me to DIAG faster?
- Do I always make it on time? Which mode offers the safest, most reliable commute when there is a strict lecture start deadline?

To answer these questions, Table 1 aggregates my 20 journeys by transport modality, transposing metrics into rows for direct comparison.

> **Table 1: Modal Performance Comparison (Student S1)**

| Commute Metric            | Bicycle                                                      | Public Transport                                              | *Overall (S1)*                                                  |
|:------------------------- |:------------------------------------------------------------:|:-------------------------------------------------------------:|:---------------------------------------------------------------:|
| **Trip Count**            | 7                                                            | 13                                                            | *20*                                                            |
| **Average Distance**      | 10.7 km                                                      | 11.9 km                                                       | *11.5 km*                                                       |
| **Average Duration**      | 40.1 min                                                     | 45.1 min                                                      | *43.4 min*                                                      |
| **Median Duration**       | 40.0 min                                                     | 46.0 min                                                      | *41.0 min*                                                      |
| **Duration Dispersion**   | $\sigma = \pm 4.2\text{ min}$, $\text{IQR} = 4.5\text{ min}$ | $\sigma = \pm 7.3\text{ min}$, $\text{IQR} = 12.0\text{ min}$ | *$\sigma = \pm 6.7\text{ min}$, $\text{IQR} = 10.5\text{ min}$* |
| **Total Cost (Avg/Trip)** | €0.00 (€0.00)                                                | €32.24 (€2.48)                                                | *€32.24 (€1.61)*                                                |
| **Late Trips (Rate)**     | 0 (0.0%)                                                     | 3 (23.1%)                                                     | *3 (15.0%)*                                                     |
| **Average Margin**        | +7.7 min                                                     | +5.8 min                                                      | *+6.5 min*                                                      |

Several clear findings emerge from this initial aggregation:

- **Speed:** On average, cycling is faster than public transit: 40.1 minutes by bicycle versus 45.1 minutes by public transport (medians of 40.0 min vs. 46.0 min). A 5-minute saving on an 11-kilometer journey might seem modest, and in fact it must be interpreted along the other findings.
- **Predictability:** Cycling times are thinly spread ($\sigma = \pm 4.2\text{ min}$, $\text{IQR} = 4.5\text{ min}$), meaning I will know to a certain degree the time I will arrive. Public transit, on the other hand, is more volatile ($\sigma = \pm 7.3\text{ min}$, $\text{IQR} = 12.0\text{ min}$, spanning from 35 to 55 minutes). By employing my own vehicle I'm less bounded by external factors, public transit is dependent on them instead. I was never late when cycling, but I have been with public transport (3 times over 13).
- **Behavioral Paradox:** Cycling strictly public transport across all three performance axes: it is faster, completely free, and 100% punctual. Yet, I chose public transport for nearly two-thirds of my commutes. This reveals that the real practical trade-off is independent to speed and money: over an 11 km urban route, physical fatigue and bad weather make paying €2.48 and accepting the risk of being late an acceptable compromise for comfort.

While the summary table captures aggregate statistics, it conceals day-to-day fluctuations. To see how these commutes unfolded across the month, Figure 1 combines two views sharing a common 5-minute vertical scale.

> **Figure 1: Commute Duration Timeline & Modal Variability**

![Figure 1: Trip Duration & Punctuality (S1)](img/me/timeline_duration.svg)

The chart is divided into two purposeful subplots:

- **On the left, the Daily Timeline** displays individual trip data across the month timeline. It displays four complementary properties into each single day:
  - **Bar height** indicates the door-to-door duration, colored by mode (Green for Bicycle, Purple for Public Transport).
  - **The horizontal black segment** marks the average duration for that specific mode (40.1 min for bike, 45.1 min for transit).
  - **The floating point** represents the time the lecture started relative to when I left home (my planned trip buffer: `duration + arrival margin`).
  - **Visual margin & punctuality color:** The vertical gap between the top of each bar and its floating point indicates my arrival margin. If the point floats above the bar I arrived early (blue circle), if the bar overlaps or exceeds the point I arrived late (red cross).
- **On the right, the Duration Boxplot** offers a side-by-side summary of transport mode variability. The horizontal axis specifies the distance traveled on average by mode (`Bicycle (10.7 km)` vs. `Public transport (11.9 km)`), while the Tukey boxes, black median lines, whiskers, and outlier marks capture the distribution variability.

Two deeper empirical insights stand out from this visualization:

1. **Habitual Consistency in Departure Time:**
   By observing the floating points across the timeline, a behavioral habit becomes apparent: my departure buffer is almost perfectly constant. The points hover horizontally around the 50-minute line. Knowing that my commute takes roughly 40 to 45 minutes on average, I leave home about 50 minutes before lecture start, expecting a 5-to-10 minute buffer regardless of how I travel.

2. **The Anatomy of Transit Delays:**
   Because of this fixed 50-minute departure habit, punctuality hinges entirely on whether the chosen mode can reliably stay under that 50-minute ceiling:
   
   - When cycling, my travel time remained between 35 and 42 minutes on 6 out of 7 days, leaving plenty of buffer. Even on October 22, when an unusual delay stretched my bicycle ride to 48 minutes (visible as an outlier on the boxplot), the 50-minute buffer still protected me.
   - When taking public transport, however, external factors frequently pushed travel times beyond the 50-minute threshold. Spikes on October 5 (5 min late), October 13 (4 min late), and October 19 (1 min late) clearly exceed the deadline points.
