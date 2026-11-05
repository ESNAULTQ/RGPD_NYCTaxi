# Jour 3 — conservation, qualité, tâches et audit

Exécuter les sections dans l'ordre dans Snowsight. Les résultats ci-dessous sont des attendus calculés sur les CSV fournis ; ne cocher qu'après observation réelle.

## 0. Prérequis

- [x] Les tests du jour 2 sont validés, y compris les refus intentionnels de `GOUVERNANCE` et `PUBLIC`.
- [x] Les volumes avant purge sont `400 / 25 951 / 25 933 / 3 / 400 / 914`.
- [x] Le stage RH est vide.
- [x] Les politiques de masquage et de lignes sont actives.
- [x] La feuille Snowsight a permis l'exécution des fichiers complets indiqués.

## 1. Purger toutes les copies — `TRANSFORMER`

Exécuter **en entier** `snowflake/rh/purge_rh.sql`. Le script est destructif par conception : il applique la règle R1, mais conserve l'état antérieur dans Time Travel.

Attendus au 3 novembre 2026 avec le jeu fourni :

| Contrôle | Attendu | Observé | État |
|---|---:|---:|---|
| Chauffeurs à purger | 46 | 46 lignes supprimées, confirmées dans `QUERY_HISTORY` | ☑ |
| `RAW.DRIVERS` après purge | 354 | 354 | ☑ |
| `RAW.DRIVER_SHIFTS` après purge | 25 951 | 25 951 | ☑ |
| `MARTS.DIM_DRIVER` après purge | 354 | 354 | ☑ |
| `MARTS.MART_DRIVER_MONTHLY` après purge | 914 | 914 | ☑ |
| Time Travel avant/après | 400 / 354 | 400 / 354 avec `BEFORE (STATEMENT => query_id)` | ☑ |
| Services sans chauffeur connu | 25, donc sous le seuil bloquant de 50 | 25 | ☑ |

Le fichier fourni ne contient aucun service rattaché aux 46 chauffeurs supprimés. Le compteur des services reste donc identique. Nous purgeons néanmoins explicitement `DRIVER_SHIFTS` : un prochain fichier pourrait en contenir.

## 2. Limiter Time Travel et prouver le stage vide — `TRANSFORMER`

Exécuter `snowflake/rh/conservation_rh.sql`.

- [x] Les quatre tables personnelles ont `RETENTION_TIME = 1` (observé).
- [x] `LIST @NYC_TAXI.RAW.RH_STAGE` ne renvoie aucun fichier (observé).
- [x] La preuve Time Travel `400 / 354` est conservée sans valeur RH.

Après un jour, la version supprimée n'est plus interrogeable par Time Travel. Comme ces tables sont permanentes, elle entre ensuite dans le Fail-safe Snowflake pendant 7 jours. Ce délai n'est pas paramétrable et ne constitue pas un accès utilisateur : seule une récupération exceptionnelle par Snowflake est possible.

## 3. Lire les règles de qualité — `TRANSFORMER`

Le dossier `snowflake/rh/controles/` contient les huit règles contractuelles, une requête par fichier. Elles peuvent être exécutées séparément avant la création des tâches.

Attendus après purge :

| Règle | Anomalies attendues | Observées | Seuil | Statut |
|---|---:|---:|---:|---|
| `licence_unique` | 4 | 4 | 0 | `ALERTE` |
| `telephone_renseigne` | 12 | 12 | 14,50 (5 % de 290 actifs) | `OK` |
| `email_valide` | 7 | 7 | 0 | `ALERTE` |
| `dates_coherentes` | 8 | 8 | 0 | `ALERTE` |
| `depot_connu` | 9 | 9 | 0 | `ALERTE` |
| `service_rattache` | 25 | 25 | 50 | `OK` |
| `service_unique` | 18 | 18 | 0 | `ALERTE` |
| `duree_plausible` | 14 | 14 | 0 | `ALERTE` |

`ALERTE` n'arrête pas le pipeline sauf pour `service_rattache`. Le dépassement est strictement `nb_anomalies > seuil` : 50 anomalies seraient encore au seuil, 51 bloqueraient.

## 4. Créer et tester le catalogue — `TRANSFORMER`, puis `ANALYSTE`

Exécuter `snowflake/rh/catalogue/vue_catalogue.sql` en entier.

Attendu pour les deux rôles :

| Table | Colonnes |
|---|---:|
| `DIM_DEPOT` | 4 |
| `DIM_DRIVER` | 12 |
| `MART_DRIVER_MONTHLY` | 8 |

- [x] `ANALYSTE` obtient les trois tables et 24 lignes au total (4 + 12 + 8 observées).
- [x] La vue ne contient aucune valeur RH, seulement des métadonnées.
- [x] La vue expose sensibilité, conservation et tags personnels par colonne.

## 5. Créer le graphe — `TRANSFORMER`

Exécuter `snowflake/rh/taches_rh.sql` en entier. Le graphe est :

```text
T_PURGE (07:00 Europe/Paris) -> T_QUALITE -> T_TABLES
```

Les tâches sont créées suspendues. `T_TABLES` utilise uniquement `INSERT OVERWRITE`, ce qui conserve tables, tags, commentaires et politiques.

Observation : les trois tâches ont été créées sous `TRANSFORMER` et observées `SUSPENDED`. `T_PURGE` porte le cron `0 7 * * * Europe/Paris`, `T_QUALITE` dépend de `T_PURGE` et `T_TABLES` dépend de `T_QUALITE`.

Activez et lancez une exécution manuelle :

```sql
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('NYC_TAXI.MARTS.T_PURGE');
EXECUTE TASK NYC_TAXI.MARTS.T_PURGE;
```

Attendre environ une minute, puis exécuter les blocs V35 et V36 de `verification_jour3.sql`.

- [x] `T_PURGE`, `T_QUALITE` et `T_TABLES` sont `SUCCEEDED` (exécution manuelle observée le 4 novembre 2026).
- [x] La dernière mesure de qualité contient exactement huit lignes au même horodatage.
- [x] Les avertissements non bloquants n'ont pas empêché `T_TABLES` de réussir.
- [x] `service_rattache` est historisé `OK` avec 25 pour un seuil de 50 ; `telephone_renseigne` est `OK` avec 12 pour 14,50.

## 6. Prouver le blocage

Cette démonstration ne modifie aucune donnée RH. Exécutez en entier
`snowflake/rh/taches_rh_test_blocage.sql` : il suspend le graphe, remplace
temporairement `T_QUALITE` par une variante au seuil 0, active et lance le graphe.

1. attendez environ une minute ;
2. vérifiez que `T_QUALITE` est `FAILED` et que `T_TABLES` ne démarre pas ;
3. vérifiez la ligne `service_rattache` 25 / 0 / `ALERTE` ;
4. **restaurez immédiatement** la tâche en réexécutant `taches_rh.sql` ;
5. réactivez, relancez et confirmez les trois succès.

- [x] Une ligne `service_rattache` 25 / 0 / `ALERTE` est historisée lors du test, à côté de la ligne de production 25 / 50 / `OK`.
- [x] L'historique prouve que `T_QUALITE` a échoué sur le seuil temporaire 0 et que `T_TABLES` n'a pas démarré.
- [x] Le seuil final est revenu à 50 ; l'exécution suivante a remis `T_PURGE`, `T_QUALITE` et `T_TABLES` en `SUCCEEDED`.

## 7. Non-régression et audit

Exécuter `snowflake/rh/verification_jour3.sql` avec `TRANSFORMER`, puis `snowflake/gouvernance/06_audit.sql` avec `ACCOUNTADMIN`.

- [x] Volumes après purge et reconstruction : `354 / 25 951 / 25 933 / 3 / 354 / 914` (observés).
- [x] Aucun chauffeur n'est hors conservation (`0` observé).
- [x] Le masquage de `DIM_DRIVER` reste effectif après reconstruction : 354 noms/e-mails/licences masqués, 342 téléphones masqués, 12 NULL, 354 dates limitées à l'année et `driver_id` visible.
- [x] Il manque 0 description dans `DIM_DEPOT` et `DIM_DRIVER` (observé après reconstruction).
- [x] L'audit affiche utilisateur, rôle, objet, date et `query_id`, sans valeur RH ; rôles observés : `RH_PAIE`, responsables de dépôt, `ANALYSTE`, `TRANSFORMER`, `ACCOUNTADMIN` et exécutions `SYSTEM`.

`ACCESS_HISTORY` peut avoir environ 3 heures de retard. Un résultat vide immédiatement après les tests ne prouve donc pas une absence d'accès : attendre puis relancer.

Le catalogue a également été revérifié après `T_TABLES` : `DIM_DEPOT` 4, `DIM_DRIVER` 12 et `MART_DRIVER_MONTHLY` 8.

## 8. Captures et arrêt final

Ajouter dans `docs/` quatre captures anonymisées :

1. lignage de `MART_DRIVER_MONTHLY` ;
2. graphe des tâches et une exécution réussie ;
3. huit lignes de `QUALITE_RESULTATS` sans valeur RH ;
4. audit d'accès avec utilisateurs et rôles.

Suspendre enfin la racine :

```sql
USE ROLE TRANSFORMER;
ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;
```

- [x] `T_PURGE` est `SUSPENDED` avec le motif `USER_SUSPENDED`.
- [x] Les observations réelles sont reportées dans ce fichier et `REGISTRE.md`.
- [ ] Les captures ont été inspectées le 5 novembre 2026 : aucune valeur personnelle ni secret n'est visible, mais `02_tags_dim_driver.png` doit encore être recadrée pour retirer l'identifiant du compte Snowflake avant publication.

### Critère de sortie

Le jour 3 est terminé lorsque la purge et Time Travel sont prouvés, les huit mesures sont historisées, le graphe réussit puis bloque lors du test contrôlé, les protections survivent à la reconstruction, l'audit nomme utilisateurs et rôles, et la racine est suspendue.
