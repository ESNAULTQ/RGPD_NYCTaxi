# Screenshot evidence — strict procedure

Follow this procedure in order. Do not move to the next element until the
current element passes its validation gate.

## General rules for every screenshot

Before starting:

1. Create or use the folder `docs/` at the repository root.
2. Use PNG format.
3. Use the exact filename requested by the element.
4. Maximise the result area and use 80–90% browser zoom if necessary.
5. Hide or crop the browser address bar, Snowflake account locator, personal
   e-mail, notifications and unrelated browser tabs.
6. Never show a row containing a chauffeur's name, e-mail, telephone, licence,
   birth date or another clear RH value.
7. Keep the active role, object name, column headers, aggregate values and
   statuses readable.
8. Open the saved PNG and inspect all four corners before accepting it.

Do not execute the purge again. Do not repeat the blocking test. Do not resume
the scheduled tasks merely to obtain a screenshot.

---

## Element 1 — Real regulatory-watch subscription

### Objective

Prove that the legal watch is genuinely active, rather than only described in
`VEILLE.md`.

### Filename

`docs/01_veille_abonnement.png`

If EUR-Lex cannot appear in the same tool, use two files:

- `docs/01a_veille_sources.png`
- `docs/01b_veille_eurlex.png`

### Action

No Snowflake SQL is required.

1. Open the selected watch tool.
2. Subscribe to the CNIL news/RSS source.
3. Subscribe to or monitor the EDPB/CEPD news page.
4. Subscribe to a EUR-Lex GDPR update, saved search or alert.
5. Confirm that each subscription is active.
6. Display the source/subscription list, not the content of a personal e-mail.

### The screenshot must show

- the watch tool name or recognisable interface;
- CNIL;
- EDPB/CEPD;
- EUR-Lex, either in the same image or the second image;
- an active/followed/subscribed state.

### The screenshot must not show

- personal e-mail address;
- password or token;
- private profile information;
- unrelated subscriptions.

### Information to report with the image

- tool used;
- activation date;
- review frequency;
- responsible reader;
- backup reader.

### PASS gate

PASS only when three official sources are actively monitored and the evidence is
anonymous. Otherwise, correct the subscription or screenshot before continuing.

---

## Element 2 — Tags on `DIM_DRIVER`

### Objective

Prove that table-level and personal-data tags are present in Snowsight.

### Filename

`docs/02_tags_dim_driver.png`

If the interface cannot show both tag levels in one image:

- `docs/02a_tags_table_dim_driver.png`
- `docs/02b_tags_colonnes_dim_driver.png`

### Preparation

1. Sign in to Snowsight.
2. Select role `TRANSFORMER`.
3. Do not open a data preview.

### Action

1. Open **Catalog → Explorer**.
2. Navigate to **NYC_TAXI → MARTS → Tables → DIM_DRIVER**.
3. Open the table details/tags area.
4. Open the columns area to display column tags.
5. Do not click a button that changes or removes a tag.

### Expected table tags

- `SENSIBILITE = confidentiel`;
- `DUREE_CONSERVATION = 5 ans après la fin du contrat du chauffeur`.

### Expected personal column tags

| Column | `DONNEE_PERSONNELLE` value |
|---|---|
| `DRIVER_ID` | `identifiant_interne` |
| `FIRST_NAME` | `nom` |
| `LAST_NAME` | `nom` |
| `EMAIL` | `email` |
| `PHONE` | `telephone` |
| `BIRTH_DATE` | `date_naissance` |
| `TLC_LICENSE_NUMBER` | `identifiant_officiel` |

### The screenshot must show

- `NYC_TAXI.MARTS.DIM_DRIVER`;
- the tag names and values;
- enough context to prove that the tags belong to this table or its columns.

### The screenshot must not show

- Data Preview;
- RH rows;
- account locator or personal login information.

### PASS gate

PASS only when both table tags and all seven personal column tags can be read.

---

## Element 3A — Safe access proof for `RH_PAIE`

### Objective

Prove that payroll sees all current rows without publishing a clear RH value.

### Filename

`docs/03a_acces_rh_paie.png`

### Action

Open a new worksheet and run the entire block:

```sql
USE SECONDARY ROLES NONE;
USE ROLE RH_PAIE;
USE WAREHOUSE NYC_TAXI_WH;

SELECT
  CURRENT_ROLE() AS role_actuel,
  COUNT(*) AS lignes_visibles,
  COUNT_IF(driver_id = '*****') AS driver_id_masque,
  COUNT_IF(first_name = '*****') AS prenoms_masques,
  COUNT_IF(last_name = '*****') AS noms_masques,
  COUNT_IF(email = '*****') AS emails_masques,
  COUNT_IF(phone = '*****') AS telephones_masques,
  COUNT_IF(phone IS NULL) AS telephones_nuls,
  COUNT_IF(tlc_license_number = '*****') AS licences_masquees
FROM NYC_TAXI.MARTS.DIM_DRIVER;
```

### Expected result

| Column | Expected value |
|---|---:|
| `ROLE_ACTUEL` | `RH_PAIE` |
| `LIGNES_VISIBLES` | 354 |
| `DRIVER_ID_MASQUE` | 0 |
| `PRENOMS_MASQUES` | 0 |
| `NOMS_MASQUES` | 0 |
| `EMAILS_MASQUES` | 0 |
| `TELEPHONES_MASQUES` | 0 |
| `TELEPHONES_NULS` | 12 |
| `LICENCES_MASQUEES` | 0 |

### The screenshot must show

- the result column headers;
- the complete result row;
- `ROLE_ACTUEL = RH_PAIE`.

### The screenshot must not show

- a query selecting individual columns without aggregation;
- clear RH values.

### PASS gate

PASS only when 354 rows are visible and all mask counters are zero.

---

## Element 3B — Safe masking proof for `ANALYSTE`

### Objective

Prove that the exact same access pattern is masked for the analyst.

### Filename

`docs/03b_acces_analyste.png`

### Action

Open a new worksheet and run the entire block:

```sql
USE SECONDARY ROLES NONE;
USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;

SELECT
  CURRENT_ROLE() AS role_actuel,
  COUNT(*) AS lignes_visibles,
  COUNT_IF(driver_id = '*****') AS driver_id_masque,
  COUNT_IF(first_name = '*****') AS prenoms_masques,
  COUNT_IF(last_name = '*****') AS noms_masques,
  COUNT_IF(email = '*****') AS emails_masques,
  COUNT_IF(phone = '*****') AS telephones_masques,
  COUNT_IF(phone IS NULL) AS telephones_nuls,
  COUNT_IF(tlc_license_number = '*****') AS licences_masquees
FROM NYC_TAXI.MARTS.DIM_DRIVER;
```

### Expected result

| Column | Expected value |
|---|---:|
| `ROLE_ACTUEL` | `ANALYSTE` |
| `LIGNES_VISIBLES` | 354 |
| `DRIVER_ID_MASQUE` | 0 |
| `PRENOMS_MASQUES` | 354 |
| `NOMS_MASQUES` | 354 |
| `EMAILS_MASQUES` | 354 |
| `TELEPHONES_MASQUES` | 342 |
| `TELEPHONES_NULS` | 12 |
| `LICENCES_MASQUEES` | 354 |

### The screenshot must show

- the same result columns as Element 3A;
- the complete result row;
- `ROLE_ACTUEL = ANALYSTE`.

### PASS gate

PASS only when the expected counters match and no clear value is displayed.

---

## Element 4 — Lineage of `MART_DRIVER_MONTHLY`

### Objective

Prove the upstream data flow of the monthly driver mart.

### Filename

`docs/04_lineage_mart_driver_monthly.png`

### Preparation

1. Select role `TRANSFORMER`.
2. Do not execute or modify a table.

### Action

1. Open **Catalog → Database Explorer**.
2. Navigate to **NYC_TAXI → MARTS → Tables → MART_DRIVER_MONTHLY**.
3. Select the **Lineage** tab.
4. Expand upstream nodes with `+` if necessary.
5. Centre the graph so the object names and arrows are readable.

### The screenshot must show

- the target `MART_DRIVER_MONTHLY`;
- upstream objects available in the graph;
- arrows showing the flow direction;
- database/schema context.

### The screenshot must not show

- Data Preview;
- individual values;
- an unrelated table lineage.

### PASS gate

PASS only when the target and at least one upstream relationship are readable.

---

## Element 5 — Successful task graph

### Objective

Prove that the normal chain executed successfully in dependency order.

### Filename

`docs/05_taches_succes.png`

If the graph and run statuses cannot fit in one image:

- `docs/05a_graphe_taches.png`
- `docs/05b_historique_taches_succes.png`

### Preparation

1. Select role `TRANSFORMER`.
2. Leave `T_PURGE` suspended.
3. Do not use **Run**, **Resume** or **Retry**.

### Action

1. Open **Transformation → Tasks → Task Graphs**.
2. Filter database `NYC_TAXI` and schema `MARTS`.
3. Open root task graph `T_PURGE`.
4. Open the successful run from 4 November 2026 around 06:32 in the timezone
   displayed by Snowflake.
5. Display the graph and/or run details.

Alternative navigation:

**Catalog → Explorer → NYC_TAXI → MARTS → Tasks → T_PURGE → Graph / Run History**.

### Expected chain

```text
T_PURGE SUCCEEDED -> T_QUALITE SUCCEEDED -> T_TABLES SUCCEEDED
```

### The screenshot must show

- all three task names;
- dependency direction;
- `SUCCEEDED` for all three tasks;
- enough date/time context to prove they belong to the same run.

### PASS gate

PASS only when all three successful states and their dependency chain are
demonstrated. The current root state may be `SUSPENDED`; that is expected.

---

## Element 6 — Latest complete quality measurement

### Objective

Prove the eight contract quality measurements from the restored normal task.

### Filename

`docs/06_qualite_resultats.png`

### Action

Run:

```sql
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

WITH mesures_completes AS (
  SELECT mesure_le
  FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
  GROUP BY mesure_le
  HAVING COUNT(*) = 8
     AND COUNT(DISTINCT regle) = 8
)
SELECT regle, mesure_le, nb_anomalies, seuil, statut
FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
WHERE mesure_le = (
  SELECT MAX(mesure_le)
  FROM mesures_completes
)
ORDER BY regle;
```

### Expected result

| Rule | Anomalies | Threshold | Status |
|---|---:|---:|---|
| `dates_coherentes` | 8 | 0 | `ALERTE` |
| `depot_connu` | 9 | 0 | `ALERTE` |
| `duree_plausible` | 14 | 0 | `ALERTE` |
| `email_valide` | 7 | 0 | `ALERTE` |
| `licence_unique` | 4 | 0 | `ALERTE` |
| `service_rattache` | 25 | 50 | `OK` |
| `service_unique` | 18 | 0 | `ALERTE` |
| `telephone_renseigne` | 12 | 14.50 | `OK` |

### The screenshot must show

- exactly eight rows;
- all five result columns;
- the same `MESURE_LE` for all rows;
- readable anomaly, threshold and status values.

### PASS gate

PASS only when the eight rows match the expected normal measurement. A single
`service_rattache` row with threshold 0 is the controlled test and does not pass
this element.

---

## Element 7 — Pseudonymised access audit

### Objective

Prove which roles accessed `DIM_DRIVER`, without publishing the real login name
or RH data.

### Filename

`docs/07_audit_acces.png`

### Action

Run:

```sql
USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;

WITH acces_dim_driver AS (
  SELECT
    ah.query_id,
    ah.query_start_time,
    ah.user_name,
    objet.value:objectName::string AS object_name
  FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah,
       LATERAL FLATTEN(input => ah.base_objects_accessed) objet
  WHERE ah.query_start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND REPLACE(UPPER(objet.value:objectName::string), '"', '')
        = 'NYC_TAXI.MARTS.DIM_DRIVER'
),
preuves AS (
  SELECT
    a.query_start_time,
    a.user_name,
    COALESCE(q.role_name, 'SYSTEM') AS role_name,
    a.object_name,
    a.query_id,
    ROW_NUMBER() OVER (
      PARTITION BY COALESCE(q.role_name, 'SYSTEM')
      ORDER BY a.query_start_time DESC
    ) AS rang
  FROM acces_dim_driver a
  LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY q
    ON q.query_id = a.query_id
)
SELECT
  query_start_time,
  IFF(user_name = 'SYSTEM', 'SYSTEM', 'PROJECT_USER') AS user_name,
  role_name,
  object_name,
  query_id
FROM preuves
WHERE rang = 1
ORDER BY role_name;
```

### Expected result

The result should include as many of these roles as available:

- `RH_PAIE`;
- `RESP_DEPOT_QUEENS`;
- `RESP_DEPOT_BRONX`;
- `ANALYSTE`;
- `TRANSFORMER`;
- `ACCOUNTADMIN`;
- `SYSTEM`.

### The screenshot must show

- `QUERY_START_TIME`;
- pseudonymised `USER_NAME`;
- `ROLE_NAME`;
- `NYC_TAXI.MARTS.DIM_DRIVER`;
- `QUERY_ID`.

### The screenshot must not show

- the real project login name;
- SQL text containing RH values;
- result data from `DIM_DRIVER`.

### PASS gate

PASS when the audit names the object and multiple business/technical roles. If
the latest access is missing, wait for `ACCOUNT_USAGE` latency and run the same
query later; do not create unsafe reads merely to populate the screenshot.

---

## Element 8 — Controlled blocking proof (strongly recommended)

### Objective

Prove that a quality failure prevents `T_TABLES` from starting, and that the
normal task was restored afterwards.

### Filename

`docs/08_taches_blocage.png`

### Preparation

Do not run `taches_rh_test_blocage.sql` again. Query history only.

### Action

Run:

```sql
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

SELECT name, state, error_message, scheduled_time, completed_time
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TASK_HISTORY(
  SCHEDULED_TIME_RANGE_START => DATEADD(day, -7, CURRENT_TIMESTAMP()),
  SCHEDULED_TIME_RANGE_END => CURRENT_TIMESTAMP(),
  RESULT_LIMIT => 200
))
WHERE name IN ('T_PURGE', 'T_QUALITE', 'T_TABLES')
  AND query_id IS NOT NULL
ORDER BY scheduled_time DESC, name;
```

### Expected proof

The relevant history must show:

1. controlled run: `T_PURGE SUCCEEDED`;
2. controlled run: `T_QUALITE FAILED` with the temporary threshold-0 message;
3. no `T_TABLES` run belonging to that failed chain;
4. later restored run: all three tasks `SUCCEEDED`.

### PASS gate

PASS only when both the blocked test and later restoration are visible. If the
history has expired, do not rerun a destructive demonstration solely for a
screenshot; keep the existing documented result.

---

## Final delivery gate

The evidence package is complete when the following files have been manually
reviewed:

- [x] `01a_veille_sources.png` : CNIL et CEPD actifs ; EUR-Lex est documenté en revue manuelle faute de compte ;
- [ ] `02_tags_dim_driver.png` : contenu conforme, recadrage final requis pour retirer l'identifiant du compte Snowflake ;
- [x] `03a_acces_rh_paie.png` ;
- [x] `03b_acces_analyste.png` ;
- [x] `04_lineage_mart_driver_monthly.png` ;
- [x] paire `05a_graphe_taches.png` / `05b_historique_taches_succes.png` ;
- [x] `06_qualite_resultats.png` ;
- [x] `07_audit_acces.png` ;
- [x] `08_taches_blocage.png`.

Send or save the files one element at a time. Each image should be validated
against its PASS gate before continuing.

