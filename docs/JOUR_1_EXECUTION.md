# Jour 1 — ordre d'exécution et preuves

Cette checklist prépare le jour 1 sans confondre résultat attendu et résultat observé. Ne cocher une preuve qu'après exécution réelle dans Snowflake.

## 0. Garde-fous avant Snowflake

- [x] `git status --short` n'affiche aucun CSV.
- [x] `git ls-files data/` ne renvoie rien.
- [x] Le compte Snowflake est en édition Enterprise, confirmé par l'usage effectif des fonctions de gouvernance.
- [x] Le responsable du projet exécute les scripts et relève les preuves.
- [x] La région est relevée : `SELECT CURRENT_REGION();` → **observé :** `AWS_EU_WEST_3` (AWS EU Paris).
- [x] L'absence des contrats/DPA Snowflake et des lieux de support est documentée comme écart à valider par le DPO ou le propriétaire du contrat ; aucune conclusion n'est inventée.

Arrêter l'exécution si les CSV apparaissent dans Git ou si le compte n'est pas Enterprise.

## 1. Installation — `ACCOUNTADMIN`

Exécuter en entier :

```text
snowflake/00_installation.sql
```

Attendu : warehouse `NYC_TAXI_WH`, base `NYC_TAXI`, schémas `RAW`, `STAGING`, `MARTS`, rôle `TRANSFORMER` attribué à l'utilisateur courant.

- [x] `SHOW SCHEMAS IN DATABASE NYC_TAXI` affiche `RAW`, `STAGING`, `MARTS`.
- [x] `SHOW GRANTS TO ROLE TRANSFORMER` confirme les droits du pipeline.
- [x] **Observations / écarts :** installation conforme ; les écarts juridiques et contractuels sont consignés dans `VEILLE.md`.

## 2. Veille et inventaire — sans SQL

- [x] `docs/VEILLE.md` distingue les faits connus des éléments juridiques restant **À CONFIRMER**.
- [x] CNIL et CEPD sont actifs dans Inoreader ; EUR-Lex est contrôlé manuellement chaque mois faute de compte disponible.
- [x] Une capture anonymisée des abonnements actifs est enregistrée dans `docs/01a_veille_sources.png`.
- [x] Le responsable du projet est désigné pour la lecture et la continuité ; fréquences hebdomadaire et mensuelle consignées.
- [x] L'inventaire de `docs/REGISTRE.md` a été relu par le responsable du projet ; l'absence de second relecteur est assumée.

Le dispositif n'est pas « configuré » tant que l'abonnement réel et la capture n'existent pas.

## 3. Ingestion — `TRANSFORMER`

1. Exécuter `snowflake/rh/chargement_rh_1_preparer.sql`.
2. Dans Snowsight, déposer `data/drivers.csv` et `data/driver_shifts.csv` sur `NYC_TAXI.RAW.RH_STAGE`.
3. Vérifier `LIST @NYC_TAXI.RAW.RH_STAGE;` → attendu : 2 fichiers.
4. Exécuter `snowflake/rh/chargement_rh_2_copier.sql`.
5. Rejouer le second script pour vérifier l'idempotence du chargement.

| Contrôle | Attendu | Observé |
|---|---:|---:|
| `RAW.DRIVERS` | 400 | 400 |
| `RAW.DRIVER_SHIFTS` | 25 951 | 25 951 |
| Fichiers sur `RH_STAGE` après copie | 0 | 0 |
| Lignes ajoutées au second passage | 0 | 0 |

## 4. STAGING et MARTS — `TRANSFORMER`

Exécuter strictement dans cet ordre :

1. `snowflake/rh/00_tables_rh.sql`
2. `snowflake/rh/staging/stg_rh__drivers.sql`
3. `snowflake/rh/staging/stg_rh__driver_shifts.sql`
4. `snowflake/rh/marts/dim_depot.sql`
5. `snowflake/rh/marts/dim_driver.sql`
6. `snowflake/rh/marts/mart_driver_monthly.sql`

| Contrôle | Attendu avant purge | Observé |
|---|---:|---:|
| `STAGING.STG_RH__DRIVER_SHIFTS` | 25 933 | 25 933 |
| `MARTS.DIM_DEPOT` | 3 | 3 |
| `MARTS.DIM_DRIVER` | 400 | 400 |
| `MARTS.MART_DRIVER_MONTHLY` | 914 | 914 |

## 5. Fondation de gouvernance

Dans la base d'exemple séparée, exécuter d'abord :

1. `exemples/00_bac_a_sable.sql`
2. `exemples/01_role_gouvernance.sql`

Observer la différence entre propriété, `USAGE`, `SELECT` et droits globaux. Le nettoyage `exemples/99_nettoyage.sql` reste facultatif et ne doit être lancé qu'après avoir terminé les exemples.

Exécuter `snowflake/gouvernance/01_gouvernance.sql` en entier. Le fichier change lui-même de rôle aux endroits nécessaires.

- [x] Trois tags visibles dans `NYC_TAXI.GOUVERNANCE`.
- [x] `QUALITE_RESULTATS` existe avec les colonnes contractuelles.
- [x] `GOUVERNANCE` n'a reçu aucun `SELECT` sur `RAW` ou `MARTS` ; le refus intentionnel a été observé.
- [x] `TRANSFORMER` peut appliquer les tags et écrire les résultats de qualité.

## 6. Catalogue — `TRANSFORMER`

Exécuter :

1. `snowflake/gouvernance/modele_catalogue_dim_depot.sql`
2. `snowflake/rh/catalogue/catalogue_raw_drivers.sql`
3. `snowflake/rh/catalogue/catalogue_dim_driver.sql`
4. `snowflake/rh/catalogue/catalogue_raw_driver_shifts.sql`
5. `snowflake/rh/catalogue/catalogue_mart_driver_monthly.sql`

Puis exécuter `snowflake/rh/verification_jour1.sql`.

- [x] Zéro description manquante pour `RAW.DRIVERS`.
- [x] Zéro description manquante pour `MARTS.DIM_DRIVER`.
- [x] Zéro description manquante pour `MARTS.DIM_DEPOT`.
- [x] Les quatre tables RH ont sensibilité et durée de conservation.
- [x] Les identifiants, noms, coordonnées, naissance et licence portent les tags prévus.
- [x] Capture anonymisée des tags de `DIM_DRIVER` enregistrée dans `docs/02_tags_dim_driver.png`.

## 7. Fin de journée

- [x] Les résultats réellement observés sont reportés dans cette checklist.
- [x] Les écarts sont reportés dans le README sans modifier le contrat.
- [x] Les CSV et secrets ne sont pas suivis par Git ; contrôle renouvelé le 5 novembre 2026.
- [x] `VEILLE.md` et `REGISTRE.md` ont été relus par le responsable du projet ; aucun second membre n'est disponible.

### Critère de sortie

Le jour 1 est terminé seulement lorsque l'ingestion est rejouable, le stage est vide, les volumes sont observés, le catalogue est appliqué, la veille est réellement configurée et les preuves sont conservées sans donnée RH visible.
