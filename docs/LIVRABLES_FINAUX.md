# Final deliverables — strict handoff checklist

This file is the final gate before submission. A deliverable is complete only when
its acceptance criterion is satisfied. Never invent an observation and never
publish a real RH value, credential, token, account locator or private URL.

For the exact click-by-click and query-by-query screenshot procedure, follow
[`GUIDE_CAPTURES.md`](GUIDE_CAPTURES.md).

## 1. What is already complete

The following work has been implemented and observed in Snowflake:

- [x] Day 1 ingestion, MARTS, governance schema, tags, comments and catalogue.
- [x] Day 2 roles, masking policies and depot row-access policy.
- [x] Day 3 purge, Time Travel proof, one-day retention and empty stage.
- [x] Eight quality rules and their history in `QUALITE_RESULTATS`.
- [x] Normal task run: `T_PURGE`, `T_QUALITE`, `T_TABLES` all succeeded.
- [x] Controlled blocking test: `T_QUALITE` failed and `T_TABLES` did not run.
- [x] Normal threshold restored and a new three-task run succeeded.
- [x] Effective masking, catalogue, descriptions and access audit rechecked.
- [x] Root task `T_PURGE` suspended after the demonstration.

The remaining items below require evidence, external context or an action by the
project team. SQL results copied into chat are useful, but do not replace the
required anonymised evidence stored in the repository.

## 2. Required repository

The final repository must be public and named `hudson-cab-gouvernance`.

Acceptance criteria:

- [ ] The public GitHub URL is available and opens without authentication.
- [x] `README.md`, `CONTRAT_GOUVERNANCE.md`, `GUIDE_BRIEF_GOUVERNANCE.md`,
      `RESSOURCES.md`, `docs/`, `snowflake/` and `exemples/` are present.
- [x] The two CSV files are absent from Git and from the complete Git history.
- [x] No `.env`, private key, password, token, account locator or private URL is
      committed.
- [ ] The final commit is pushed and `git status --short` is empty.

Run these commands from the repository root before every push:

```bash
git status --short
git ls-files data/
git check-ignore -v data/drivers.csv data/driver_shifts.csv
```

Expected result:

- `git ls-files data/` prints nothing;
- `git check-ignore` lists both CSV files and the matching `.gitignore` rule;
- after the final commit, `git status --short` prints nothing.

If a CSV was ever committed, stopping tracking in the latest commit is not
enough: the public repository must be recreated or its history must be cleaned
before publication.

## 3. Required anonymised evidence in `docs/`

Use the exact filenames below. PNG is preferred so the evaluator can open the
evidence directly on GitHub.

| File | Required content | Pass condition |
|---|---|---|
| `01a_veille_sources.png` | Real subscriptions to CNIL and EDPB; EUR-Lex manual fallback documented in `VEILLE.md` | Tool/source and active subscriptions are visible; no personal e-mail or private URL |
| `02_tags_dim_driver.png` | Snowsight details/tags for `NYC_TAXI.MARTS.DIM_DRIVER` | The contractual tags and values are readable; no RH row is visible |
| `03a_acces_rh_paie.png` | Safe aggregate query executed as `RH_PAIE` | Role and aggregate result are visible; no real RH value |
| `03b_acces_analyste.png` | The exact same aggregate query executed as `ANALYSTE` | Role and masked counters are visible; no real RH value |
| `04_lineage_mart_driver_monthly.png` | Snowsight Lineage for `MART_DRIVER_MONTHLY` | Upstream objects and target are readable |
| `05a_graphe_taches.png` and `05b_historique_taches_succes.png` | Task graph/history for the normal run | All three tasks are `SUCCEEDED` in dependency order |
| `06_qualite_resultats.png` | Latest normal set in `QUALITE_RESULTATS` | Eight rules share one timestamp; thresholds and statuses are readable |
| `07_audit_acces.png` | Result of `06_audit.sql` | Date, role, object and audit event are visible; no RH value |

Recommended additional proof:

| File | Required content | Pass condition |
|---|---|---|
| `08_taches_blocage.png` | Controlled blocking run | `T_PURGE` succeeded, `T_QUALITE` failed and no `T_TABLES` run exists for that chain |
| `09_purge_time_travel.png` | Time Travel aggregate proof | Only `400` before and `354` after are shown |
| `10_retention_stage.png` | Retention and stage evidence | Four tables show retention `1`; the stage result is empty |

Before saving every image:

- crop the browser address bar, account locator and session information;
- hide personal e-mail addresses and real login names where applicable;
- never show a row from `DIM_DRIVER`, `DRIVERS` or `DRIVER_SHIFTS`;
- retain the Snowflake role, object name, aggregate counters and status needed to
  understand the proof;
- open the saved image once and inspect all corners before committing it.

Current final check: `02_tags_dim_driver.png` contains the correct table and
column evidence, but its left panel/breadcrumb still exposes the Snowflake
account identifier. Crop that identifier before the Git commit.

For the Day 2 comparison, execute the following query unchanged under each role.
It proves masking without displaying a value:

```sql
USE SECONDARY ROLES NONE;
USE ROLE RH_PAIE; -- replace only this role with ANALYSTE for the second proof
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

Current post-purge acceptance criteria:

- `RH_PAIE`: 354 visible rows and zero masked counters;
- `ANALYSTE`: 354 visible rows, names/e-mails/licences masked on 354 rows,
  phones masked on 342 rows, 12 null phones, and zero masked `driver_id` values.

Do not display clear `RH_PAIE` fields to prove that they are clear. Zero masked
counters are sufficient and safe.

## 4. `docs/ACCES.md` must contain observed results

The table contains the A01 to A10 and P01 to P04 observations. Historical Day 2
grids that were not retained are identified explicitly; current aggregate
non-regression evidence is linked without publishing RH values.

Rules:

- [x] Keep the original Day 2 expected values in the `Attendu` column.
- [x] Put the actual result and execution date in `Observé`.
- [x] Mark the line complete only when the result was actually observed.
- [x] A07 and A09 pass when access is refused; do not grant extra privileges to
      make these queries succeed.
- [x] Never paste the clear values of `D0003` or another chauffeur.
- [x] Record the temporary Brooklyn extension test only if Brooklyn was removed
      again from `ACCES_DEPOT` afterwards.

The Day 2 baseline was measured before the purge: 400 drivers. The current state
contains 354. Do not silently replace the Day 2 baseline with current counts. If
the original detailed result is no longer available, write this explicitly, for
example: `Conforme observé avant purge le 03/11/2026; détail non conservé`, then
add a dated post-purge non-regression result. Do not reload the CSV merely to
recover a missing screenshot.

For P03, the effective post-reconstruction test under `ANALYSTE` is acceptable
evidence even when `POLICY_REFERENCES` returns no rows because of metadata
visibility. The observed aggregate was 354 protected rows.

## 5. Legal watch and unresolved context

`docs/VEILLE.md` contains the legal analysis, four source sheets and the actual
watch state. CNIL and EDPB are active in Inoreader. EUR-Lex is reviewed manually
each month because account creation did not succeed; no automatic EUR-Lex alert
is claimed.

Information the team must provide:

- [x] tool used for the watch, for example Feedly, Inoreader, Thunderbird or
      My EUR-Lex;
- [x] actual subscription date;
- [x] three official sources monitored: CNIL and EDPB automatically, EUR-Lex manually;
- [x] review frequency: weekly for CNIL/EDPB and monthly for EUR-Lex, unless a
      stricter documented schedule is chosen;
- [x] responsible reader and backup reader, using team roles or first names only
      if the repository is public;
- [x] `docs/01a_veille_sources.png` as proof of the two active subscriptions;
      the EUR-Lex manual fallback is documented rather than falsely presented as
      an active alert.

The source table records the real tool and state, including the EUR-Lex
limitation. It does not claim that an alert is active when it is not.

The following legal facts may remain unresolved, but they must remain visibly
labelled `À CONFIRMER` and must not be invented:

- exact controller/joint-controller relationship between the European and US
  entities;
- legal basis for each HR purpose;
- New York employment-law retention requirements;
- Snowflake DPA, support locations, replication and subprocessors;
- international-transfer mechanism, if one is required.

For each unavailable fact, the deliverable must state who should validate it
(`DPO`, legal counsel or contract owner). An explicit, assigned gap is acceptable;
a fabricated legal conclusion is not.

## 6. Required Markdown deliverables

Before submission, verify each document:

| Document | Required final content |
|---|---|
| `README.md` | Project purpose, prerequisites, architecture, execution order, decisions, known limits and evidence links |
| `docs/VEILLE.md` | Territorial analysis, real watch setup, four source sheets, contract/legal comparison and assigned gaps |
| `docs/REGISTRE.md` | Personal-data inventory, data flows, recipients, retention, security, quality, audit and known limits |
| `docs/ACCES.md` | Rights map plus observed A01–A10 and P01–P04 results |
| `docs/JOUR_1_EXECUTION.md` | Day 1 observations and evidence status |
| `docs/JOUR_2_EXECUTION.md` | Day 2 observations, intentional refusals and evidence status |
| `docs/JOUR_3_EXECUTION.md` | Purge, quality, task, blocking, audit and final suspension observations |

Final documentation acceptance criteria:

- [x] No operational `À renseigner` remains in `docs/ACCES.md`.
- [x] The watch setup no longer says `À CONFIGURER` or `À DÉSIGNER`.
- [x] Legal unknowns remain explicitly marked `À CONFIRMER` rather than guessed.
- [x] Every checked box refers to an actual observation or an explicitly
      identified confirmation where the historical grid was not retained.
- [x] Dates distinguish the pre-purge Day 2 baseline from post-purge Day 3.
- [x] The README links this checklist and the evidence guide; deliverable files
      link the evidence they use.

## 7. Presentation — excluded from this delivery

The project owner confirmed on 5 November 2026 that the 15-minute presentation
is not required for this handoff. The outline below is retained as optional
preparation and is not a release blocker.

If a presentation is requested later, the optional outline below can be used.

Strict timing:

| Time | Speaker | Content |
|---:|---|---|
| 0:00–0:45 | Both | Problem, fictional dataset and objective |
| 0:45–5:00 | Speaker 1 | GDPR territorial analysis, official sources, real watch and unresolved legal gaps |
| 5:00–6:30 | Speaker 2 | RAW → STAGING → MARTS architecture and separation of duties |
| 6:30–8:30 | Speaker 2 | RBAC, masking and row filtering; show the safe role comparison |
| 8:30–10:30 | Speaker 2 | Purge, one-day Time Travel, empty stage and Fail-safe limitation |
| 10:30–12:30 | Speaker 2 | Eight quality rules and the normal task run |
| 12:30–13:45 | Speaker 2 | Controlled blocking run and restoration |
| 13:45–14:30 | Speaker 2 | Catalogue and access audit |
| 14:30–15:00 | Both | Known limits and conclusion |

Optional presentation safeguards:

- Rehearsal lasts 15 minutes or less.
- Speaker 1 presents the watch; Speaker 2 presents governance and the live
      demonstration.
- The live demonstration uses only aggregate or metadata queries.
- `T_PURGE` is not left enabled after the demonstration.
- A fallback sequence of the saved screenshots is ready if Snowsight is slow.
- No CSV or clear personal value appears on screen.

## 8. What the project team must send or confirm

To close the project, provide only these items:

1. the public GitHub repository URL;
2. the required anonymised PNG files listed in section 3 — completed;
3. the watch tool, activation date, reader and backup reader — documented;
4. the aggregate A01–A10 and P01–P04 observations, with an explicit note for any
   original pre-purge detail that was not retained — documented;
5. confirmation that presentation evidence is out of scope for this delivery.

Do **not** send or commit the two CSV files, clear RH results, Snowflake password,
token, private key, account locator, recovery code or private connection URL.

## 9. Definition of done

The project is ready for submission only when all of the following are true:

- [ ] Sections 2 through 8 above pass.
- [x] Required evidence is present and manually inspected.
- [x] `docs/ACCES.md` and the watch setup have no operational placeholders.
- [x] Legal unknowns are transparent and assigned for validation.
- [ ] The public repository contains no source data or secret.
- [x] The normal and blocking task evidence is preserved and the root task is
      suspended.
- [x] Presentation evidence is explicitly out of scope for this delivery.

