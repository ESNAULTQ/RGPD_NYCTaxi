# Hudson Cab Partners — gouvernance des données RH dans Snowflake

Ce dépôt met en œuvre le brief `hudson-cab-gouvernance` : ingestion de données RH fictives, catalogue, contrôle des accès, conservation, qualité et audit dans Snowflake Enterprise.

> **État actuel :** jours 1, 2 et 3 exécutés dans Snowflake. Purge, Time Travel, rétention, qualité, catalogue, graphe normal et bloquant, audit, preuves anonymisées et suspension finale ont été observés. La veille CNIL/CEPD est active ; EUR-Lex reste en revue manuelle faute de compte. La publication GitHub finale reste à effectuer.

## Confidentialité du dépôt

Les fichiers `data/drivers.csv` et `data/driver_shifts.csv` restent locaux et sont exclus par `.gitignore`. Ils ne doivent jamais être ajoutés à Git, même si les personnes sont fictives. Avant chaque publication :

```bash
git status --short
git ls-files data/
```

La seconde commande doit rester vide. Les captures publiées dans `docs/` doivent être anonymisées et ne contenir ni valeur RH, ni jeton, ni identifiant de connexion.

## Prérequis

- compte Snowflake **Enterprise** ;
- rôle `ACCOUNTADMIN` disponible pour l'installation et les délégations ;
- région Snowflake relevée avec `SELECT CURRENT_REGION();` ;
- deux CSV présents localement dans `data/` ;
- résultats et captures consignés sans inventer d'exécution.

## Architecture cible

```text
CSV locaux
  -> RAW.RH_STAGE
  -> RAW.DRIVERS / RAW.DRIVER_SHIFTS
  -> STAGING.STG_RH__DRIVERS / STG_RH__DRIVER_SHIFTS
  -> MARTS.DIM_DEPOT / DIM_DRIVER / MART_DRIVER_MONTHLY
  -> rôles métier protégés par masquage et accès par dépôt
```

Le rôle `TRANSFORMER` charge et transforme. Le rôle `GOUVERNANCE` possède les tags et politiques, mais ne reçoit aucun `SELECT` sur les données RH.

### Mécanisme de chargement

- `CSV_RH` est le format de fichier qui décrit à Snowflake comment interpréter les CSV : en-tête ignoré, champs éventuellement entre guillemets et types convertis dans la requête de copie.
- `RAW.RH_STAGE` est un espace Snowflake temporaire où les deux fichiers sont déposés avant ingestion.
- `COPY INTO` lit le stage, ajoute les métadonnées de source et charge les tables RAW. L'historique de chargement empêche de reprendre le même fichier lors d'un simple rejeu.
- `PURGE = TRUE` retire chaque fichier du stage après une copie réussie, ce qui applique la règle R3. Le résultat doit être prouvé avec `LIST @NYC_TAXI.RAW.RH_STAGE`.

## Exécution du jour 1

La checklist détaillée se trouve dans [`docs/JOUR_1_EXECUTION.md`](docs/JOUR_1_EXECUTION.md). Ordre résumé :

1. exécuter `snowflake/00_installation.sql` avec `ACCOUNTADMIN` ;
2. compléter les faits non connus dans `docs/VEILLE.md` et configurer réellement la veille ;
3. exécuter les deux scripts de chargement avec `TRANSFORMER`, avec dépôt manuel des CSV entre les deux ;
4. créer les tables, vues et MARTS dans l'ordre indiqué par le guide ;
5. exécuter les exemples `00_bac_a_sable.sql` et `01_role_gouvernance.sql`, puis `snowflake/gouvernance/01_gouvernance.sql` ;
6. exécuter le modèle `DIM_DEPOT`, puis les quatre fiches dans `snowflake/rh/catalogue/` ;
7. exécuter `snowflake/rh/verification_jour1.sql` et reporter les observations.

## Gouvernance — décisions et écarts à suivre

| Sujet | Décision ou constat au jour 1 | Suite |
|---|---|---|
| Publication des CSV | Interdite par `.gitignore` | Vérifier avant chaque commit |
| Droit applicable | Article 3(1) du RGPD probablement applicable car la gestion et les décisions sont exercées depuis Paris | Faire valider les rôles exacts des entités et l'établissement principal |
| Région et transferts | `AWS_EU_WEST_3`, soit AWS EU Paris, observée le 3 novembre 2026 | Examiner contrat, support, réplication et sous-traitants Snowflake |
| Conservation 5 ans | Règle contractuelle appliquée, mais sa justification juridique pour des contrats new-yorkais reste à confirmer | Validation DPO/juriste et droit local |
| Taxonomie du tag personnel | Les valeurs imposées couvrent les identifiants, noms et coordonnées, mais pas toutes les données professionnelles indirectes | Les inventorier malgré l'absence de valeur de tag adaptée |
| Résultats d'exécution | Jour 1 : `400 / 25 951 / 25 933 / 3 / 400 / 914`, stage vide, descriptions complètes et tags observés ; tests du jour 2 signalés conformes | Conserver les captures anonymisées et renseigner les preuves du jour 3 |

Le contrat reste inchangé. Un écart juridique ou technique est signalé ici et dans `docs/VEILLE.md`, jamais corrigé en réécrivant le contrat.

## Documents de travail

- `docs/LIVRABLES_FINAUX.md` : checklist stricte de remise, preuves requises, contrôles Git et déroulé de présentation ;
- `docs/GUIDE_CAPTURES.md` : procédure stricte, élément par élément, pour produire et valider les captures anonymisées ;
- `docs/VEILLE.md` : champ territorial, dispositif de veille, quatre fiches et comparaison au contrat ;
- `docs/REGISTRE.md` : inventaire des colonnes au jour 1, registre finalisé au jour 3 ;
- `docs/ACCES.md` : carte des droits au jour 1, tests attendus puis observés au jour 2 ;
- `docs/JOUR_1_EXECUTION.md` : ordre, rôles, contrôles et preuves du jour 1.
- `docs/JOUR_2_EXECUTION.md` : rôles métier, politiques, tests isolés et reconstruction du jour 2.
- `docs/JOUR_3_EXECUTION.md` : purge, Time Travel, qualité, catalogue, tâches, audit et arrêt final.

## Exécution du jour 2

Après validation du jour 1 :

1. relire les attendus déjà figés dans `docs/ACCES.md` ;
2. exécuter `snowflake/gouvernance/02_roles_metier.sql` avec `ACCOUNTADMIN` ;
3. exécuter `03_masquage.sql`, puis `04_acces_depot.sql` avec `GOUVERNANCE` ;
4. exécuter `verification_jour2.sql` bloc par bloc, avec rôles secondaires désactivés ;
5. rejouer les transformations avec `TRANSFORMER` et retester les protections.

Décisions : masque texte `*****`, date non autorisée `NULL`, date analyste limitée à l'année via un `01-01` synthétique, `driver_id` visible des rôles métier et correspondance dépôt extensible par table.

## Exécution du jour 3

Suivre [`docs/JOUR_3_EXECUTION.md`](docs/JOUR_3_EXECUTION.md). Ordre résumé :

1. exécuter `snowflake/rh/purge_rh.sql` en entier avec `TRANSFORMER` et conserver les compteurs et la preuve Time Travel ;
2. exécuter `conservation_rh.sql`, puis contrôler la rétention à un jour et le stage vide ;
3. lire ou tester les huit requêtes de `snowflake/rh/controles/` ;
4. créer `GOUVERNANCE.V_CATALOGUE` avec `catalogue/vue_catalogue.sql` et la lire sous `ANALYSTE` ;
5. créer, activer et lancer le graphe avec `taches_rh.sql`, puis prouver son succès et son blocage contrôlé ;
6. exécuter `verification_jour3.sql`, puis `gouvernance/06_audit.sql` avec `ACCOUNTADMIN` ;
7. prendre les quatre captures anonymisées et suspendre `MARTS.T_PURGE`.

### Décisions de conservation et d'orchestration

- Le seuil de purge est dynamique : `end_date < DATEADD(year, -5, CURRENT_DATE())`. Un fichier historique complet peut donc réintroduire des lignes anciennes dans `RAW`, mais la purge quotidienne les supprime avant qualité et reconstruction.
- R1 couvre `DRIVER_SHIFTS`, `DIM_DRIVER` et `MART_DRIVER_MONTHLY`, pas seulement `RAW.DRIVERS`. Les copies MARTS sont purgées dès `T_PURGE` afin qu'un blocage de qualité ne laisse pas une copie arrivée à échéance.
- Les vues `STAGING` ne stockent pas de copie : elles reflètent automatiquement la purge de `RAW`.
- `T_TABLES` utilise `INSERT OVERWRITE`, jamais `CREATE OR REPLACE TABLE`, pour conserver les commentaires, tags et politiques.
- Les sept règles non bloquantes peuvent produire `ALERTE` sans interrompre le graphe. Seul `service_rattache > 50` fait échouer `T_QUALITE`.
- Time Travel est limité à un jour. Les tables permanentes conservent ensuite un Fail-safe Snowflake de 7 jours, non configurable et non interrogeable par les utilisateurs.

## Limites et actions manuelles restantes

- la région observée est `AWS_EU_WEST_3`, mais les clauses contractuelles, le support, les réplications et la qualification exacte des entités restent à faire valider ;
- la veille CNIL et CEPD est active dans Inoreader depuis le 5 novembre 2026 ; la création du compte My EUR-Lex n'ayant pas abouti, EUR-Lex fait l'objet d'une revue manuelle mensuelle explicitement documentée ;
- les observations de purge, rétention, tâches et audit ont été reportées depuis Snowsight et leurs captures anonymisées sont conservées dans `docs/` ;
- `ACCESS_HISTORY` peut avoir environ trois heures de retard ; un résultat vide immédiat doit être retesté ;
- la tâche racine doit rester suspendue après la démonstration pour éviter une consommation quotidienne de crédits.

La présentation orale de 15 minutes n'est pas incluse dans le périmètre de remise confirmé par le responsable du projet le 5 novembre 2026 ; elle n'est donc pas un critère bloquant de cette livraison.
