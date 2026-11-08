// ==============================================================================
// VISUAL ANALYTICS 2026/2027 — HOMEWORK ASSIGNMENT REPORT
// Sapienza University of Rome
// Author: Emanuele Scaccia 2006749
// Dataset: HW_030_scaccia.2006749.csv (80 trips, Oct 5 – Oct 30, 2026)
// ==============================================================================

// Classic LaTeX / B&W Document Configuration
#set document(
  title: "Getting to DIAG: How much does a journey really cost?",
  author: "Emanuele Scaccia 2006749",
  date: auto
)

#set page(
  paper: "a4",
  margin: (x: 2.5cm, top: 2.8cm, bottom: 2.8cm),
  header: context {
    if counter(page).get().first() > 1 [
      #set text(size: 9pt, font: "New Computer Modern")
      #grid(
        columns: (1fr, 1fr),
        align(left)[Visual Analytics],
        align(right)[Sapienza University of Rome]
      )
      #v(-0.35em)
      #line(length: 100%, stroke: 0.4pt + black)
    ]
  },
  footer: context {
    if counter(page).get().first() > 1 [
      #set text(size: 9pt, font: "New Computer Modern")
      #line(length: 100%, stroke: 0.4pt + black)
      #v(0.25em)
      #grid(
        columns: (1fr, 1fr),
        align(left)[Emanuele Scaccia 2006749],
        align(right)[#counter(page).display()]
      )
    ]
  }
)

#set text(
  font: "New Computer Modern",
  size: 9.8pt,
  fill: black,
  lang: "en"
)

#set par(
  justify: true,
  leading: 0.62em,
  spacing: 1.05em
)

#show raw: set text(font: "New Computer Modern", size: 8.8pt)

#show heading: it => [
  #set text(fill: black, font: "New Computer Modern", weight: "bold")
  #it
]

#show heading.where(level: 1): it => [
  #v(1.1em)
  #text(size: 13.5pt, weight: "bold")[#it.body]
  #v(0.5em)
]

#show heading.where(level: 2): it => [
  #v(0.9em)
  #text(size: 11.5pt, weight: "bold")[#it.body]
  #v(0.35em)
]

#show heading.where(level: 3): it => [
  #v(0.7em)
  #text(size: 10.2pt, weight: "bold")[#it.body]
  #v(0.25em)
]

#show figure.caption: set text(size: 8.8pt)
#show figure.where(kind: table): set figure.caption(position: top)
#show figure: set figure(gap: 0.75em)
#show figure: it => [
  #v(0.5em)
  #it
  #v(0.5em)
]

// LaTeX-style Badges & Blocks
#let badge-supported = text(weight: "bold")[[SUPPORTED]]
#let badge-contradicted = text(weight: "bold")[[CONTRADICTED]]
#let badge-discovery = text(weight: "bold")[[EMPIRICAL DISCOVERY]]

#let latex-box(title: none, body) = {
  v(0.25em)
  rect(
    width: 100%,
    stroke: 0.5pt + black,
    fill: none,
    radius: 0pt,
    inset: (x: 10pt, y: 7pt)
  )[
    #if title != none [
      #text(weight: "bold", size: 9.3pt)[#title]
      #v(0.25em)
    ]
    #set text(size: 9.2pt)
    #body
  ]
  v(0.25em)
}

#let confounder-box(body) = {
  v(0.2em)
  block(
    width: 100%,
    stroke: (left: 1.5pt + black),
    inset: (left: 7pt, y: 1pt)
  )[
    #text(weight: "bold", size: 8.5pt)[Confounders & Limitations:] #h(4pt)
    #text(size: 8.6pt, style: "italic")[#body]
  ]
  v(0.2em)
}

#let highlight-box(body) = {
  v(0.25em)
  block(
    width: 100%,
    stroke: (left: 1.5pt + black),
    inset: (left: 8pt, y: 2pt)
  )[
    #set text(size: 8.8pt)
    #set par(leading: 0.55em, spacing: 0.65em)
    #body
  ]
  v(0.25em)
}



// ==============================================================================
// FRONTFACE (COVER PAGE)
// Must contain ONLY:
// 1. Header (course and university)
// 2. Homework title (Getting to DIAG:\nHow much does a journey really cost?)
// 3. Identification (Emanuele Scaccia 2006749)
// 4. Homework month/year (November 2026)
// ==============================================================================

#align(center)[
  #v(2.5cm)
  #text(size: 14pt)[
    Visual Analytics \
    Sapienza University of Rome
  ]
  
  #v(5.5cm)
  
  #text(size: 22pt, weight: "bold")[
    Getting to DIAG:\
    How much does a journey really cost?
  ]
  
  #v(5.5cm)
  
  #text(size: 12pt)[
    Emanuele Scaccia 2006749
  ]
  
  #v(0.8em)
  
  #text(size: 12pt)[
    November 2026
  ]
]

#pagebreak()


// ==============================================================================
// INTRODUCTION & DATASET SCHEMA (TABLE 1)
// ==============================================================================

= Introduction

This report explores, both statistically and visually, what it really costs to commute daily to Sapienza's DIAG for lectures. When thinking about "cost", we rarely just mean money. Instead, three distinct dimensions shape the daily commute:

- *Travel time:* door-to-door duration.
- *Monetary cost:* direct expenses per trip.
- *Arrival reliability:* punctuality relative to lecture start.

Data is collected across four students labelled $S_1$ through $S_4$, myself being $S_1$. It spans approximately one month of travel time (October 5 to October 30, 2026) on weekdays, totaling 20 journeys per student and 80 trips overall.

The underlying dataset records seven attributes for every one-way journey (@tab:schema):

#figure(
  caption: [Dataset schema (`HW_030_scaccia.2006749.csv`)],
  table(
    columns: (1.4fr, 1.1fr, 3.5fr),
    stroke: none,
    table.hline(stroke: 1pt + black),
    table.header([*Field*], [*Type*], [*Description*]),
    table.hline(stroke: 0.5pt + black),
    [`student_id`], [Categorical], [Student identifier (`S1` for myself; `S2`, `S3`, `S4` for colleagues).],
    [`date`], [Temporal], [Date of trip (October 5 to October 30, 2026).],
    [`mode`], [Categorical], [Transport mode chosen (`Bicycle`, `Public transport`, `Car`, `Walk`).],
    [`distance_km`], [Quantitative], [One-way distance covered in kilometers.],
    [`duration_min`], [Quantitative], [Door-to-door trip time in minutes.],
    [`cost_eur`], [Quantitative], [Direct out-of-pocket monetary cost in Euro.],
    [`arrival_margin_min`], [Quantitative], [Required arrival time minus actual arrival time (positive = early, late otherwise).],
    table.hline(stroke: 1pt + black),
  )
) <tab:schema>

= 1. Individual Commute Analysis

To begin, let's explore my own commute data as Student $S_1$. Living roughly 11.5 km away from DIAG, I alternate between two modes: I cycle whenever suitable, and take public transport otherwise.

Knowing my routine, I ask myself three questions:

+ Cycling is free, but how much do I actually spend when taking public transit?
+ On average, what is the door-to-door duration of both means, and which one gets me to DIAG faster?
+ Do I always make it on time? Which mode offers the safest, most reliable commute when there is a strict lecture start deadline?

@tab:modal_s1 aggregates my 20 journeys by transport modality to compare performance across the three core dimensions.

#pagebreak()

#figure(
  caption: [Modal Performance Comparison (Student S1)],
  table(
    columns: (1.8fr, 1.1fr, 1.1fr, 1.2fr),
    align: (left, center, center, center),
    stroke: none,
    table.hline(stroke: 1pt + black),
    table.header([*Commute Metric*], [*Bicycle*], [*PT*], [*Overall (S1)*]),
    table.hline(stroke: 0.5pt + black),
    [*Trip Count*], [7], [13], [_20_],
    [*Average Distance*], [10.7 km], [11.9 km], [_11.5 km_],
    [*Average Duration*], [40.1 min], [45.1 min], [_43.4 min_],
    [*Median Duration*], [40.0 min], [46.0 min], [_41.0 min_],
    [*Duration Spread (IQR)*], [4.5 min], [12.0 min], [_10.5 min_],
    [*Total Cost (Avg/Trip)*], [€0.00 (€0.00)], [€32.24 (€2.48)], [_€32.24 (€1.61)_],
    [*Late Trips (Rate)*], [0 (0.0%)], [3 (23.1%)], [_3 (15.0%)_],
    [*Average Margin*], [+7.7 min], [+5.8 min], [_+6.5 min_],
    table.hline(stroke: 1pt + black),
  )
) <tab:modal_s1>

#highlight-box[
  - *Task:* Directly compare modal performance for Student $S_1$ and look up summary statistics.
  - *Data:* 20 filtered journeys ($S_1$) partitioned by `mode` (`Bicycle`, `PT`, `Overall`) across 8 metrics: distance, duration central tendency and IQR spread, monetary expenses, tardiness rate, and average arrival margin.
  - *Encoding:* Transposed tabular matrix mapping categorical transport modes to columns and quantitative commute metrics to rows.
]

Several findings emerge from this initial aggregation:

- *Speed:* On average, cycling is faster than public transit: 40.1 minutes by bicycle versus 45.1 minutes by public transport (medians of 40 min vs. 46 min). A 5-minute saving on an 11-kilometer journey might seem modest, and in fact it must be interpreted along the other findings.
- *Predictability:* Cycling times are thinly spread (IQR = 4.5 min), meaning I will know to a certain degree the time I will arrive. Public transit, on the other hand, is more volatile (IQR = 12.0 min, spanning from 35 to 55 minutes). By employing my own nimble vehicle I'm less bounded by external factors, public transit is dependent on them instead. I was never late when cycling, but I have been with public transport (3 times over 13).
- *Behavioral Paradox:* Cycling is better than public transport across all three performance axes: it is faster, completely free, and 100% punctual. Yet, I chose public transport for nearly two-thirds of my commutes. This reveals that the real practical trade-off is independent to speed and money: over an 11 km urban route, physical fatigue and bad weather make paying €2.48 and accepting the risk of being late an acceptable compromise for comfort.

#pagebreak()

While the summary table captures aggregate statistics, it conceals day-to-day fluctuations. To see how these commutes unfolded across the month, @fig:timeline combines two views sharing a common 5-minute vertical scale.

#figure(
  image("img/me/timeline_duration.svg", width: 90%),
  caption: [Commute Duration Timeline & Modal Variability (Student S1)]
) <fig:timeline>

#highlight-box[
  - *Task:* Jointly inspect day-to-day commute fluctuations and detect punctuality anomalies across the month (left), while comparing duration distribution shape and dispersion between modes (right).
  - *Data:* 20 individual trips for $S_1$; attributes: `date` (temporal), `duration_min` (quantitative), `mode` (nominal), derived planned buffer (`duration + arrival_margin`), mode mean duration, and `punctuality_status` (nominal).
  - *Encoding:* Dual-view composite sharing a 5-minute quantitative vertical scale:
    - *Daily Timeline (left):* Bar marks (height = duration, color hue = mode: green for Bicycle, azure for Public Transport); tick marks (mode mean duration); point marks (vertical position = departure buffer / lecture start, shape and color = punctuality: blue circle for on-time, red cross for late; vertical gap between bar and point = arrival margin).
    - *Duration Boxplot (right):* Tukey boxplots grouped by mode (horizontal axis annotated with average distance); marks show median (black line), IQR box, whiskers, and outlier points.
]

Two deeper empirical insights stand out from this visualization:

+ *Consistency in Departure Time:*
  By observing the floating points across the timeline, a behavioral habit becomes apparent: my departure buffer is almost perfectly constant. The points hover horizontally around the 50-minute line. Knowing that my commute takes roughly 40 to 45 minutes on average, I leave home about 50 minutes before lecture start, expecting a 5-to-10 minute buffer regardless of how I travel.

+ *The Anatomy of Transit Delays:*
  Because of this fixed 50-minute departure habit, punctuality hinges entirely on whether the chosen mode can reliably stay under that 50-minute ceiling:
  - When cycling, my travel time remained between 35 and 42 minutes on 6 out of 7 days, leaving plenty of buffer. Even on October 22, when an unusual delay stretched my bicycle ride to 48 minutes (visible as an outlier on the boxplot), the 50-minute buffer still protected me.
  - When taking public transport, however, external factors frequently pushed travel times beyond the 50-minute threshold. Spikes on October 5 (5 min late), October 13 (4 min late), and October 19 (1 min late) clearly exceed the deadline points.

#pagebreak()

// ==============================================================================
// SECTION 2: GROUP COMMUTE ANALYSIS (STUDENTS S1 - S4)
// ==============================================================================

= 2. Group Commute Analysis

Having analyzed my own habits, I now compare my routine with my three classmates. The 80 recorded journeys capture four distinct commuter realities: Student $S_4$ living within walking distance (1.9 km), Student $S_3$ with a short cycle route (6.8 km), myself ($S_1$) at a medium-long distance (11.5 km), and Student $S_2$ facing the longest daily trip across town (14.1 km).

Looking at the four of us, three questions guide this comparative analysis:

+ *Distance vs. Time:* Does living further away naturally translate into a linearly longer commute?
+ *Modal Reliability:* Does active travel provide safer, more reliable punctuality than motorized transit?
+ *Distance vs. Cost:* Do commute expenses scale proportionally with route distance?

To evaluate the group's commute dynamics, @tab:group_profiles aggregates individual student profiles across the distance gradient, while @tab:modal_efficiency benchmarks the efficiency and economics of each transport modality.

#figure(
  caption: [Student Commute Profiles],
  [
    #set text(size: 8.2pt)
    #table(
      columns: (1.5fr, 1fr, 1fr, 1.25fr, 1fr, 1.35fr),
      align: (left, center, center, center, center, center),
      stroke: none,
      inset: (x: 3pt, y: 2.2pt),
      table.hline(stroke: 1pt + black),
      table.header([*Commute Metric*], [*Student S4*], [*Student S3*], [*Student S1 (Me)*], [*Student S2*], [*Group Benchmark*]),
      table.hline(stroke: 0.5pt + black),
      [*Average Distance*], [1.9 km], [6.8 km], [11.5 km], [14.1 km], [_8.6 km_],
      [*Modal Split*], [PT (13) \ Walk (7)], [Bike (10) \ PT (10)], [Bike (7) \ PT (13)], [Car (9) \ PT (11)], [_PT (47), Bike (17), Car (9), Walk (7)_],
      [*Typical Duration*], [19 min], [29 min], [41 min], [41 min], [_34 min_],
      [*Duration Spread (IQR)*], [7 min], [7 min], [11 min], [14 min], [_16 min_],
      [*Monthly Cost*], [€15.60], [€19.60], [€32.24], [€53.89], [_€121.33_],
      [*Late Trips (Rate)*], [1 (5.0%)], [2 (10.0%)], [3 (15.0%)], [6 (30.0%)], [_12 (15.0%)_],
      [*Median Lead*], [24 min], [35 min], [50 min], [46 min], [_38 min_],
      table.hline(stroke: 1pt + black),
    )
  ]
) <tab:group_profiles>

#highlight-box[
  - *Task:* Profile and compare commuter patterns across students.
  - *Data:* All 80 recorded trips partitioned by `student_id` ($S_4, S_3, S_1, S_2$) and `Group Benchmark` across 7 metrics (average distance, modal split counts, median duration, IQR spread, monthly expense, late trip count/rate, and median departure lead time).
  - *Encoding:* Tabular matrix where columns represent students ordered by ascending route distance (plus benchmark aggregate) and rows represent the multi-dimensional commute metrics.
]

#figure(
  caption: [Modal Efficiency & Economics across the Group],
  [
    #set text(size: 8.2pt)
    #table(
      columns: (1.4fr, 0.8fr, 0.9fr, 1.4fr, 0.8fr, 0.95fr),
      align: (left, center, center, center, center, center),
      stroke: none,
      inset: (x: 3pt, y: 2.2pt),
      table.hline(stroke: 1pt + black),
      table.header([*Commute Metric*], [*Walk*], [*Bicycle*], [*Public Transport*], [*Car*], [_All Modes_]),
      table.hline(stroke: 0.5pt + black),
      [*Trip Count*], [7], [17], [47], [9], [_80_],
      [*Min Distance*], [1.7 km], [6.3 km], [1.9 km], [13.4 km], [_1.7 km_],
      [*Max Distance*], [1.8 km], [10.8 km], [14.7 km], [13.8 km], [_14.7 km_],
      [*Door-to-Door Speed*], [4.6 km/h], [15.5 km/h], [13.3 km/h], [24.0 km/h], [_15.1 km/h_],
      [*Unit Cost*], [€0.00 / km], [€0.00 / km], [€0.20 / km], [€0.31 / km], [_€0.18 / km_],
      [*Late Trips (Rate)*], [0 (0.0%)], [0 (0.0%)], [11 (23.4%)], [1 (11.1%)], [_12 (15.0%)_],
      table.hline(stroke: 1pt + black),
    )
  ]
) <tab:modal_efficiency>

#highlight-box[
  - *Task:* Evaluate and compare door-to-door speed, unit economic cost, and punctuality reliability across all four available transport options.
  - *Data:* All 80 trips aggregated by `mode` (`Walk`, `Bicycle`, `Public Transport`, `Car`) and `All Modes` across 6 metrics: sample trip volume, route distance bounds (min/max), average door-to-door speed (km/h), unit cost (€/km), and late arrival rate.
  - *Encoding:* Tabular layout with transport modalities as columns (ordered by degree of speed) and efficiency metrics as rows.
]

Several clear patterns emerge from these tables:

- *The Long-Distance Paradox:* $S_1$ (me) and $S_2$ share the exact same median trip duration (41 min), despite $S_2$ living 2.6 km further away. By driving a private car for 9 trips (which is faster than public transport), $S_2$ offsets the added distance. However, $S_2$ is late twice as often as I am (30% vs. 15%). The reason is a behavioral habit: $S_2$ leaves home with only 46 min of lead time on average, affording barely a 5-minute buffer on a 14.1 km route, whereas my 50-minute habit over 11.5 km gives me a safer margin.
- *The High Cost of Speed:* Driving is the fastest mode (24.0 km/h), but it extracts a heavy financial toll: €0.31/km, raising $S_2$'s monthly spend to €53.89 (44% of the entire group's).
- *Public Transit Reliability:* Public transit is the preferred transport mode of the group (47 out of 80 journeys), yet it is the primary cause of tardiness: 23.4% (11) of transit rides result in late arrivals. In contrast, active modes (walking and cycling, 24 trips combined) achieved a perfect 0.0% late rate at zero expense.

To examine how trip duration and dispersion behave across these modalities, @fig:duration_dist plots door-to-door duration distributions across all four students.

#figure(
  image("img/all/duration_distribution.svg", width: 92%),
  caption: [Student Commute Duration by Mode ($S_1$ - $S_4$)]
) <fig:duration_dist>

#highlight-box[
  - *Task:* Compare commute duration distributions, dispersion, and delays across students and transportation modes.
  - *Data:* All 80 records. Variables: Student ID, transport modality, trip duration, trip count grouped by mode and student.
  - *Encoding:* Distance-sorted categorical X-axis (Student ID), nominal X-offset (Transport Mode), and quantitative Y-axis (Trip Duration). Tukey boxplot marks encode median (black line), IQR box, and whiskers; box width encodes trip count. Point marks encode on-time outliers (circles) and late arrivals (crosses). Color hue distinguishes transport mode (green for Bicycle, azure for Public Transport, orange for Car, pink for Walk).
]

Several striking patterns emerge from this duration overview:

+ *Variance Scaling with Route Distance:* For short commutes ($S_4$ at 1.9 km), travel times are tightly bound (IQR of 1 min for walking, 3 min for public transport). As distance increases ($S_1$ and $S_2$), distributions stretch drastically (IQR of 10–12 min), and the tails reach extreme durations.
+ *Short-Distance Waiting ($S_4$):* On a 1.9 km route, walking takes a median of 23 min, while public transport takes 17 min. Transit saves barely 6 minutes, most likely because of waiting times that consume most of the journey. Furthermore, public transport exposes $S_4$ to heavy unreliability (the 33-minute outlier).
+ *Profiling of Late Trips:* The crosses that mark a late arrival always fall on or above the upper whisker. Tardiness, in these cases, can reliably be attributed to traffic or external factors. There is a small exception in $S_2$, but we previously established their delays to thin-margin departures.

#pagebreak()

While @fig:duration_dist visualizes duration, it does not directly show whether we arrived before the lecture deadline. @fig:arrival_margin shifts the focus to our arrival margins.

#figure(
  image("img/all/arrival_margin_all.svg", width: 92%),
  caption: [Student Punctuality by Mode ($S_1$ - $S_4$)]
) <fig:arrival_margin>

#highlight-box[
  - *Task:* Assess arrival punctuality and margin distributions across all students and modes to evaluate tardiness risk.
  - *Data:* All 80 records. Variables: Student ID, transport modality, arrival margin, trip count grouped by mode and student.
  - *Encoding:* Distance-sorted categorical X-axis with modal offsets and centered quantitative Y-axis (Arrival Margin). Horizontal reference rule: red dashed line at $Y = 0$ (`Lesson Start`). Tukey boxplots with widths scaled to trip counts. Point marks: circles for early outlier arrivals, crosses for late arrivals ($Y < 0$). Color hue distinguishes transport modes (green for Bicycle, azure for Public Transport, orange for Car, pink for Walk).
]

This punctuality perspective reveals:

+ *Flawless Reliability of Active Travel:* Walking and cycling always float completely above the red dashed line. Active commuting never experienced a late arrival across the entire month.
+ *$S_2$'s Planning:* Even though we previously said that $S_2$'s tardiness was given by public transport delay, we can clearly notice that they have no problems in arriving on time by car (1 late out of 9). Given that driving is faster than taking the public transport, perhaps it can be that $S_2$ leaves at around the same time for both modalities. Further analysis could clear this.
+ *Early Biking:* The two students that bike to class (me and $S_3$) tend to arrive earlier than the rest. We can attribute this to catching some breath and refreshing before the lectures start.

#pagebreak()

@fig:duration_dist and @fig:arrival_margin summarize our entire month, but they collapse the day-to-day timeline. To observe temporal interactions and uncover city-wide events, @fig:daily_punct maps all 80 trips along the 20-weekday timeline.

#figure(
  image("img/all/daily_student_punctuality.svg", width: 78%),
  caption: [Daily Student Punctuality ($S_1$ - $S_4$)]
) <fig:daily_punct>

#highlight-box[
  - *Task:* Track punctuality day by day, detect synchronized delays across students, and identify group-wide transport mode shifts.
  - *Data:* All 80 recorded trips. Variables: Student ID, date, arrival margin, transport mode, punctuality status.
  - *Encoding:* Four vertically stacked scatterplots grouped by student (ordered by distance). X-axis: shared temporal date. Y-axis: arrival margin (scale centered at 0). Reference mark: red dashed horizontal rule at $Y = 0$ (`Lesson Start`). Point marks represent individual daily commutes. Color hue encodes mode (green = bike, azure = transit, orange = car, pink = walk). Shape encodes punctuality (circle = on-time, cross = late).
]

Comparing our commutes day by day uncovers synchronized significant commute delays:

- *October 22:*
  - $S_4$ was 10 min late.
  - $S_3$ was 19 min late.
  - $S_2$ was 13 min late.
- *October 27:*
  - $S_3$ was 15 min late.
  - $S_2$ was 10 min late.

Additionally, scanning down each column provides an indirect clue about weather conditions. Three of us ($S_4$, $S_3$, and myself) alternate between active commuting and public transit. On certain days, active travel completely vanishes from the entire group: October 8, October 12, and a consecutive three-day stretch from October 19 to 21. On October 20, all four of us took public transit simultaneously. Given that active travel is faster and free, these unanimous shifts to public transit for commodity strongly suggest bad weather on those days.

To prove whether we were late because we left home late or because the transport network failed, @fig:late_dumbbell analyses specifically the 12 late commutes.

#figure(
  image("img/all/daily_student_punctuality_late.svg", width: 78%),
  caption: [Late Commute Analysis ($S_1$ - $S_4$)]
) <fig:late_dumbbell>

#highlight-box[
  - *Task:* Isolate late arrivals to classify late departure or external problems (augmenting @fig:daily_punct).
  - *Data:* Filtered subset of 12 late trips (arrival margin $< 0$). Variables: date, Student ID, transport mode, actual arrival margin, expected arrival margin ($= "arrival margin" + ("duration" - "median duration")$).
  - *Encoding:* Four vertically stacked scatterplots grouped by student (ordered by distance). Each late event is represented by a dumbbell glyph:
    - *Colored cross:* Actual late arrival margin, colored by transport mode.
    - *Black diamond:* Expected arrival margin had the trip taken the median modal duration.
    - *Vertical dashed dropline:* Connects the diamond to the cross, segment length encodes delay beyond median travel time.
]

By looking at @fig:late_dumbbell, we can conclusively tell that the delays on October 22 and 27 were caused by external problems in the transport infrastructure across the whole city (more than 10 minutes of delay across late students). Then, individually, we can say that:

- $S_4$ and $S_3$ were late only because of public transport issues.
- My ($S_1$) tardiness on some days is caused by slower public transport than expected.
- Only $S_2$ exhibited true late departures from home.

#pagebreak()

// ==============================================================================
// SECTION 3: EXPECTATIONS
// ==============================================================================

= 3. Expectations

Before analyzing the data, my initial questions were shaped by three common intuitive assumptions regarding how distance, transport modes, and costs interact. Checking them against the visualizations reveals where these expectations hold and where the data break them.

== 3.1 Travel Time Scales Proportionally with Distance

*Contradicted*

I assumed students living further from DIAG would naturally face longer daily commutes. However, @tab:group_profiles and @fig:duration_dist show that myself ($S_1$, at 11.5 km) and $S_2$ (at 14.1 km) share the exact same median travel time of 41.0 minutes, despite a 2.6 km distance gap. $S_2$ offsets this extra distance by driving a car at 24.0 km/h (@tab:modal_efficiency), roughly 80% faster than public transit (13.3 km/h). Modal choice thus decouples travel duration from travelled distance.

== 3.2 Active Travel is More Reliable than Motorized Modes

*Supported*

I expected that by bypassing traffic jams and public transport timetables, walking and cycling would offer better punctuality. The data backs this up: across all 24 active journeys in the dataset, the late arrival rate was *exactly 0.0%* (@tab:modal_efficiency, @fig:arrival_margin), maintaining positive arrival margins every single day. In contrast, motorized travel caused *100% of the group's 12 late arrivals*, with public transit failing on 23.4% of its trips.

This conclusion, however, is bounded by distance and human endurance. While motorized modes can scale to virtually any route across town, walking and cycling are constrained by physical stamina and weather. When distance stretches or rain hits, students naturally trade away active travel's punctuality for the shelter and convenience of transit.

== 3.3 Commute Costs Scale Proportionally with Distance

*Contradicted*

One might intuitively assume that living further from the university extracts a proportionally higher financial toll. In reality, @tab:group_profiles and @tab:modal_efficiency demonstrate that commute expenses are completely decoupled from distance by modal choice. Walking and cycling cost €0.00 regardless of whether the trip is 1.7 km ($S_4$) or 10.8 km ($S_1$). Conversely, $S_2$ lives only 2.6 km further than myself, but spends €53.89 by driving a car at €0.31/km too: a monthly cost that accounts for 44% of the entire group's expenditure.

This comparison, however, only tracks direct out-of-pocket expenses (fuel and transit tickets). It omits other costs such as vehicle ownership or public transport passes, which would flatten or skew the per-kilometer economics over a longer period.

#pagebreak()

// ==============================================================================
// SECTION 4: DISCOVERIES
// ==============================================================================

= 4. Discoveries

Beyond checking my initial expectations, exploratory visual analysis revealed several unexpected behavioral habits and infrastructure phenomena that were not anticipated prior to plotting the data.

== 4.1 Synchronized City-Wide Transit Shocks

Tracking daily punctuality in @fig:daily_punct revealed that late arrivals were rarely isolated bad luck. Instead, they clustered into city-wide disruption events. On *Thursday, October 22*, three of us were late simultaneously on public transit ($S_4$ at -10 min, $S_3$ at -19 min, and $S_2$ at -13 min). On *Tuesday, October 27*, $S_3$ and $S_2$ were late again (-15 min and -10 min). @fig:late_dumbbell proves that these were transport network breakdowns rather than personal oversleeping: on both mornings, all affected students left home with positive planned buffers (+1 to +7 min).

== 4.2 The Short-Distance Transit Penalty ($S_4$)

On a 1.9 km route, one would expect public transit to be an easy upgrade. In practice, @fig:duration_dist and @tab:modal_efficiency reveal that transit saves a median of barely 6 minutes over walking (17 vs. 23 min), because fixed public transport overheads (walking to the stop, waiting, and boarding) dominate the short distance. Worse, public transit exposes $S_4$ to extreme schedule volatility, spiking to 33 minutes on October 22 and causing a 10-minute delay. Walking, meanwhile, had a tight 1-minute IQR and zero risk.

== 4.3 Modal Consensus as an Indirect Weather Proxy

Because three of us ($S_4$, $S_3$, and myself) prefer active travel for its speed and zero cost, scanning down the daily columns in @fig:daily_punct doubles as an environmental tracker. On five specific days (October 8, 12, and the consecutive October 19–21 streak), active travel completely vanished, especially on October 20 when all four of us took public transit. These shifts to public transit strongly imply rainy or poor weather mornings. Crucially, this also helps isolate October 27 as a pure transit failure rather than a weather shock, as $S_4$ walked and I cycled on that day without any weather hindrance.

#pagebreak()

// ==============================================================================
// SECTION 5: AI DISCLAIMER
// ==============================================================================

= 5. AI Disclaimer

This section provides transparency regarding the use of generative AI during the execution of this homework.

Generative AI was used (specifically #link("https://gemini.google.com")[Gemini 3.8 Flash] through #link("https://antigravity.google")[Antigravity]) as an assistant for:
+ Writing automated #link("https://www.python.org")[Python] scripts to compute the statistics reported in the tables.
+ Implementing and refining #link("https://vega.github.io/vega-lite/")[Vega-Lite] JSON specifications.
+ Checking and formatting this document written using #link("https://typst.app")[Typst].

All the analytical work, research, findings, and visualization strategies on which this document is based have been performed by myself, Emanuele Scaccia. 
