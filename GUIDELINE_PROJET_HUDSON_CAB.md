# Hudson Cab Partners — Guide de réalisation et contexte pour Codex

> **Statut :** document de cadrage opérationnel / référence de travail.  
> **Projet :** `hudson-cab-gouvernance` — gouvernance des données RH dans Snowflake.  
> **Périmètre :** exercice de 3 jours, en binôme, sur des données fictives.  
> **Question directrice :** **Qui peut voir quelle donnée, pendant combien de temps, et peut-on s'y fier ?**

## 0. Comment utiliser ce document

Ce guide accompagne le kit officiel ; il **ne remplace ni** `GUIDE_BRIEF_GOUVERNANCE.md` **ni** `CONTRAT_GOUVERNANCE.md`. Leur contenu fait autorité lorsqu'une divergence apparaît :

1. `CONTRAT_GOUVERNANCE.md` : **exigences imposées** (noms, matrice des droits, conservation, qualité). Ne pas modifier.
2. `GUIDE_BRIEF_GOUVERNANCE.md` : **ordre pédagogique et technique**, rôles à utiliser, étapes et preuves.
3. Ce document : **contexte consolidé, plan d'exécution, garde-fous et consignes à Codex**.
4. Les scripts SQL et modèles présents dans le kit : **état réel du code** à examiner avant toute modification.

**Légende :** `EXIGÉ` = spécification du kit ; `PROPOSÉ` = organisation de travail / choix à valider ; `À VÉRIFIER` = point non établi à ce stade.

### Instructions permanentes à Codex

- Commencer par **lire les fichiers existants** et proposer un plan court avant de générer du SQL.
- Ne **jamais inventer** une colonne, un rôle, un nom d'objet, un résultat d'exécution ou une règle juridique non vérifiée.
- Ne pas modifier le contrat ni remplacer les scripts fournis sans raison explicite.
- Produire des **fichiers SQL versionnés, compréhensibles et rejouables** ; ne pas demander de configurer les règles manuellement dans Snowsight.
- Pour chaque changement : préciser **le fichier, le rôle Snowflake, les prérequis, les effets et le test de validation**.
- Écrire les tests **avant** les politiques ; documenter résultats **attendus** et **observés** séparément.
- Ne pas accorder de `SELECT` supplémentaire à `GOUVERNANCE` ou à `ACCOUNTADMIN` pour contourner une erreur.
- Protéger les données RH et secrets du dépôt public, même si les personnes du jeu d'essai sont fictives.
- Favoriser les changements minimaux ; préserver les tags, politiques et descriptions lors des reconstructions.
- Ne jamais prétendre qu'une commande a été exécutée dans Snowflake sans preuve du résultat.

---

## 1. Contexte et finalité métier

**Organisation.** Hudson Cab Partners exploite des taxis jaunes à New York, depuis **Bronx**, **Brooklyn** et **Queens**. Le domaine RH est nouvellement intégré dans un entrepôt **Snowflake Enterprise**. Les utilisateurs attendus sont le service paie, deux responsables de dépôts et une analyste (Priya).

**Changement structurant.** La filiale **Hudson Cab Europe**, installée à Paris, assure désormais la gestion et détermine l'usage des données du personnel. Le contrat interne ayant été préparé avant ce changement, il faut **établir le cadre juridique applicable et relever les écarts éventuels** avant de mettre en place les contrôles. Ne pas déduire automatiquement l'absence d'application du RGPD du fait que les chauffeurs résident à New York ; analyser notamment le champ d'application territorial et les rôles des entités.

**Problèmes à résoudre.** Sans inventaire, les colonnes personnelles ne sont pas maîtrisées ; les rôles métier pourraient voir trop de données ; les départs anciens risquent de rester indéfiniment ; les erreurs des fichiers sources peuvent affecter les analyses. La solution doit être **documentée, restrictive, auditable, reproductible et testée**.

**Périmètre inclus :** veille réglementaire ; ingestion CSV ; couches `RAW` / `STAGING` / `MARTS` ; catalogue/tags ; rôles et droits ; masking ; row access ; purge / rétention ; qualité ; tâches quotidiennes ; audit et démonstration.  
**Hors périmètre :** application web, API, architecture dbt ou Python, orchestration externe ; ne les ajouter que si une nouvelle consigne les impose.

---

## 2. Sources de données et architecture

### 2.1 Sources attendues (`EXIGÉ`)

| Fichier local du kit | Description | Volume | Colonnes métier |
|---|---|---:|---|
| `data/drivers.csv` | 1 ligne par chauffeur fictif | **400 lignes** | **10** |
| `data/driver_shifts.csv` | 1 ligne par service fictif, janvier–mars 2025 | **25 951 lignes** | **8** |

Données RH : identité, e-mail, téléphone, date de naissance, licence, rattachement dépôt, dates d'emploi, activité. **Ne jamais publier les CSV dans GitHub.** Les tables RAW ajoutent les colonnes techniques `_source_file`, `_loaded_at`.

### 2.2 Flux cible

```text
CSV RH locaux (non versionnés dans Git)
          |
          v
Snowflake RAW.RH_STAGE (temporaire, purgé après COPY INTO)
          |
          v
RAW.DRIVERS + RAW.DRIVER_SHIFTS (copie fidèle)
          |
          v
STAGING.STG_RH__DRIVERS + STAGING.STG_RH__DRIVER_SHIFTS (vues de typage/normalisation)
          |
          v
MARTS.DIM_DEPOT + MARTS.DIM_DRIVER + MARTS.MART_DRIVER_MONTHLY
          |
          +----> rôle RH_PAIE
          +----> rôles RESP_DEPOT_QUEENS / RESP_DEPOT_BRONX
          +----> rôle ANALYSTE

GOUVERNANCE : tags, politiques, accès dépôt, catalogue, résultats de qualité
Tâches : T_PURGE -> T_QUALITE -> T_TABLES
```

**Séparation des responsabilités.** `TRANSFORMER` charge / transforme / exécute les tâches. `GOUVERNANCE` administre les règles, mais ne lit pas les valeurs RH. Les métiers lisent `MARTS` uniquement. La lecture de `RAW` et `STAGING` par les rôles administrateurs peut être héritée techniquement ; les politiques doivent empêcher qu'ils voient les **valeurs personnelles en clair**. Ne pas confondre *absence de droit SQL* et *résultat masqué/filtré*.

### 2.3 Noms et volumes de référence

| Objet | Résultat attendu après chargement / transformation initiale |
|---|---:|
| `NYC_TAXI.RAW.DRIVERS` | 400 |
| `NYC_TAXI.RAW.DRIVER_SHIFTS` | 25 951 |
| `NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS` | 25 933 |
| `NYC_TAXI.MARTS.DIM_DEPOT` | 3 |
| `NYC_TAXI.MARTS.DIM_DRIVER` | 400 **avant purge** |
| `NYC_TAXI.MARTS.MART_DRIVER_MONTHLY` | 914 **avant purge** |
| `LIST @NYC_TAXI.RAW.RH_STAGE` | **aucun fichier après ingestion** |

Ces nombres sont des points de contrôle **avant suppression de données anciennes**. Les nombres après purge peuvent être différents ; documenter le delta.

### 2.4 Schémas et objets imposés

- Base : `NYC_TAXI` ; warehouse : `NYC_TAXI_WH`.
- Schémas : `RAW`, `STAGING`, `MARTS`, puis `GOUVERNANCE`.
- Tables métier : `RAW.DRIVERS`, `RAW.DRIVER_SHIFTS`, `MARTS.DIM_DEPOT`, `MARTS.DIM_DRIVER`, `MARTS.MART_DRIVER_MONTHLY`.
- Table de correspondance : `GOUVERNANCE.ACCES_DEPOT(role_name, depot)`.
- Table des mesures : `GOUVERNANCE.QUALITE_RESULTATS(regle, mesure_le, nb_anomalies, seuil, statut)` ; `statut` dans `OK`, `ALERTE`.
- Catalogue : `GOUVERNANCE.V_CATALOGUE` (une ligne par colonne cataloguée des trois tables MARTS).
- Tâches : `MARTS.T_PURGE`, `MARTS.T_QUALITE`, `MARTS.T_TABLES`.

### 2.5 Colonnes contractuelles RAW

**`RAW.DRIVERS` :** `driver_id`, `first_name`, `last_name`, `email`, `phone`, `birth_date`, `tlc_license_number`, `depot`, `hire_date`, `end_date`, plus `_source_file`, `_loaded_at`.

**`RAW.DRIVER_SHIFTS` :** `shift_id`, `driver_id`, `shift_date`, `depot`, `start_hour`, `hours_worked`, `trips_count`, `revenue_usd`, plus `_source_file`, `_loaded_at`.

**À VÉRIFIER dans le code :** colonnes exactes de `DIM_DRIVER` et `MART_DRIVER_MONTHLY`, jointures, types et logique d'agrégation. La colonne dérivée `driver_name` est explicitement mentionnée par le guide : sa nature personnelle doit être inventoriée et traitée.

---

## 3. Contrat de sécurité : rôles et droits (`EXIGÉ`)

| Rôle | Portée des lignes RH | Données personnelles en clair autorisées | Accès aux objets |
|---|---|---|---|
| `RH_PAIE` | Tous les dépôts | Toutes, dans le cadre de la matrice | `MARTS` : tables RH et `DIM_DEPOT` |
| `RESP_DEPOT_QUEENS` | Queens uniquement | Nom, prénom, téléphone | `MARTS` : tables RH et `DIM_DEPOT` |
| `RESP_DEPOT_BRONX` | Bronx uniquement | Nom, prénom, téléphone | `MARTS` : tables RH et `DIM_DEPOT` |
| `ANALYSTE` | Tous les dépôts | **Aucun identifiant direct** ; année de naissance seulement | Tout `MARTS` |
| `TRANSFORMER` | Tous les dépôts | Les données nécessaires au pipeline | `RAW`, `STAGING`, `MARTS` selon besoins |
| `GOUVERNANCE` | Aucune ligne | Aucune | Crée et attache les contrôles, sans lecture RH |
| `ACCOUNTADMIN` | Aucune ligne du domaine RH accessible en résultat | Aucune | Administration ; tester refus ou 0 ligne selon droits et politiques |

**Exceptions / nuances :** `driver_id`, bien que tagué identifiant interne, **reste visible des rôles métier** pour les jointures et comptages. Un rôle métier non prévu ne doit voir aucune ligne RH. `DIM_DEPOT` n'est pas un jeu de données personnel et n'est **pas** soumis au filtre de dépôt. Les rôles métier doivent pouvoir lire le catalogue.

**Décisions d'implémentation à prendre et documenter (`PROPOSÉ`) :** masquage par tag ou colonne ; valeur masquée par type ; colonnes supprimées ou conservées dans les MARTS ; représentation de « tous les dépôts » dans `ACCES_DEPOT`. Les implémentations doivent reproduire **exactement** la matrice, y compris l'exception `driver_id` et le rôle `TRANSFORMER`.

### Garde-fous pour les tests de rôle

```sql
USE SECONDARY ROLES NONE;
USE ROLE RH_PAIE;  -- adapter selon le scénario de test
USE WAREHOUSE NYC_TAXI_WH;
-- Exécuter ensuite une requête de test et relever le résultat.
```

Répéter cet isolement pour **chaque** rôle. La hiérarchie et les rôles secondaires peuvent fausser la lecture des tests. Ne pas « corriger » le contrôle en attribuant de nouveaux droits à `ACCOUNTADMIN` ou `GOUVERNANCE`.

---

## 4. Catalogue et classification (`EXIGÉ`)

Tags dans `NYC_TAXI.GOUVERNANCE` :

| Tag | Cible | Valeurs autorisées / contenu |
|---|---|---|
| `SENSIBILITE` | Table | `public`, `interne`, `confidentiel` |
| `DONNEE_PERSONNELLE` | Colonne personnelle, **y compris dérivée** | `nom`, `email`, `telephone`, `date_naissance`, `identifiant_officiel`, `identifiant_interne` |
| `DUREE_CONSERVATION` | Table | Texte justifiant la durée (par ex. « 5 ans après la fin du contrat ») |

**Catalogue à produire :** description du rôle métier, source, fréquence de chaque table ; description **de chaque colonne** de `RAW.DRIVERS` et `MARTS.DIM_DRIVER` ; fiche plus courte pour `RAW.DRIVER_SHIFTS` et `MARTS.MART_DRIVER_MONTHLY` ; fiche du référentiel `MARTS.DIM_DEPOT`. Ne pas documenter les vues `STAGING` comme des tables indépendantes : elles prolongent RAW.

La vue `GOUVERNANCE.V_CATALOGUE` couvre **les trois tables MARTS** (`DIM_DEPOT`, `DIM_DRIVER`, `MART_DRIVER_MONTHLY`) et expose au moins table, colonne, type, description et tags. Prendre en compte les droits visibles via `INFORMATION_SCHEMA` et les références aux tags (`TAG_REFERENCES_ALL_COLUMNS`).

**Contrôles de catalogue :** zéro colonne non documentée pour `RAW.DRIVERS`, `DIM_DRIVER` et `DIM_DEPOT` ; chaque colonne personnelle de l'inventaire est taguée ; chaque table concernée reçoit sensibilité + conservation ; rôle `ANALYSTE` capable d'interroger la vue.

---

## 5. Conservation et qualité (`EXIGÉ`)

### 5.1 Conservation

- **R1** : supprimer les données des chauffeurs dont la fin de contrat date de **plus de 5 ans**, **dans toutes leurs copies** ; examiner aussi les services de `RAW.DRIVER_SHIFTS` et la reconstruction des MARTS.
- **R2** : `DATA_RETENTION_TIME_IN_DAYS = 1` sur les tables personnelles concernées ; prouver le comportement Time Travel avant/après la purge et documenter la portée du **Fail-safe** (7 jours supplémentaires sur les tables permanentes, non paramétrables comme Time Travel).
- **R3** : stage vidé après chargement (`COPY INTO` et purge du fichier selon les scripts fournis) ; contrôler `LIST`.

**Risque majeur à traiter :** si un nouveau fichier complet réintroduit des chauffeurs déjà purgés, l'ingestion doit être suivie par la purge régulière ; expliciter l'ordre et la stratégie de rechargement. Vérifier qu'aucun `INSERT OVERWRITE` de MARTS ne restaure des données que la purge devait éliminer.

### 5.2 Règles contractuelles de qualité

| Règle | Définition | Seuil | Gravité |
|---|---|---|---|
| `licence_unique` | 1 licence par chauffeur | 0 anomalie | Avertissement |
| `telephone_renseigne` | Chauffeur en poste avec téléphone | 5 % des chauffeurs en poste | Avertissement |
| `email_valide` | E-mail contenant `@` | 0 | Avertissement |
| `dates_coherentes` | Pas d'embauche future ; fin après embauche | 0 | Avertissement |
| `depot_connu` | Dépôt exactement `Bronx`, `Brooklyn` ou `Queens` | 0 | Avertissement |
| `service_rattache` | Service lié à un chauffeur connu | **50 services** | **Bloquant** |
| `service_unique` | Identifiant de service unique | 0 | Avertissement |
| `duree_plausible` | Service de 16 h maximum | 0 | Avertissement |

**Minimum imposé :** la règle fournie `licence_unique` + au moins deux autres, **dont `service_rattache`**. Les mesures viennent de `RAW` et sont historisées à **chaque exécution** dans `QUALITE_RESULTATS`. Une règle dépassant un seuil non bloquant produit `ALERTE` mais laisse poursuivre ; `service_rattache` dépassant 50 doit faire **échouer `T_QUALITE`** et empêcher **`T_TABLES`** de se lancer. Pour les pourcentages, stocker un seuil **numérique calculé** lors de la mesure. Attention à bien distinguer `>` du seuil de `>=`.

### 5.3 Graphe de tâches

```text
T_PURGE (quotidienne) --> T_QUALITE --> T_TABLES
          |                  |              |
      nettoie RAW        mesure RAW     reconstruit MARTS
                             |
                         si blocage,
                     T_TABLES ne démarre pas
```

Les tâches sont exécutées **avec les droits du propriétaire `TRANSFORMER`**. Le contenu des scripts MARTS peut être intégré dans des blocs `EXECUTE IMMEDIATE $$ BEGIN ... END; $$` pour tenir dans une seule instruction de tâche. Les scripts existants utilisent `INSERT OVERWRITE` pour conserver les protections : **ne pas remplacer par `CREATE OR REPLACE TABLE`**. Suspendre les tâches après la démonstration pour éviter une consommation quotidienne de crédits.

---

## 6. Veille réglementaire et registre (`EXIGÉ`)

**Objectif :** analyser précisément l'applicabilité du RGPD à un traitement piloté depuis Paris, identifier les acteurs (responsable / éventuels sous-traitants), la région Snowflake, les transferts internationaux pertinents, la conservation, la minimisation, l'accès et les mesures de protection. **Ne pas poser de conclusion juridique sans citer l'article et la source.**

Livrables `docs/VEILLE.md` et `docs/REGISTRE.md` :

1. Analyse du champ territorial, particulièrement **article 3 du RGPD**, avec justification et distinction des entités (à confirmer via textes officiels).
2. Dispositif de veille **réellement configuré** : au moins **3 sources officielles**, périodicité, outil d'alerte / RSS / lettre et capture.
3. Au moins **4 fiches** : référence officielle, date, enseignement, impact concret pour Snowflake.
4. Comparaison **ligne par ligne** des règles du contrat aux sources ; écarts et recommandations dans `VEILLE.md` **et** `README.md`, sans réécrire le contrat.
5. Registre : acteurs, finalités, catégories, origine, destinataires / accès, conservation, mesures, localisation / transferts, preuves et limites ; respecter les rubriques du modèle du kit.

**Sources à consulter / vérifier** : EUR-Lex (RGPD), CNIL, Comité européen de la protection des données (EDPB/CEPD), ainsi que les ressources juridiques du kit. **À VÉRIFIER :** cadre de transfert si hébergement hors EEE et statut contractuel exact des entités ; ce guide ne tranche pas ces questions à la place de la veille.

---

## 7. Organisation du dépôt (cible)

```text
hudson-cab-gouvernance/
├── README.md                            # exécution, gouvernance, décisions, limites
├── .gitignore                           # exclure data/*.csv et secrets, à confirmer
├── CONTRAT_GOUVERNANCE.md               # fourni ; non modifié
├── GUIDE_BRIEF_GOUVERNANCE.md           # fourni ; non modifié
├── GUIDELINE_PROJET_HUDSON_CAB.md        # ce document (à copier à la racine)
├── data/                                # CSV locaux NON publiés
├── docs/
│   ├── VEILLE.md                        # depuis VEILLE_MODELE.md
│   ├── REGISTRE.md                      # depuis REGISTRE_MODELE.md
│   ├── ACCES.md                         # depuis ACCES_MODELE.md
│   └── ...                              # captures de preuve anonymisées
├── exemples/                            # kit pédagogique, à ne pas recopier tel quel
└── snowflake/
    ├── 00_installation.sql              # fourni
    ├── gouvernance/
    │   ├── 01_gouvernance.sql           # rôle, schéma, tags, qualité, délégations
    │   ├── 02_roles_metier.sql          # droits des quatre rôles métier
    │   ├── 03_masquage.sql              # politiques + attachements
    │   ├── 04_acces_depot.sql           # table de correspondance + row access
    │   └── 06_audit.sql                 # historique d'accès + rôle
    └── rh/
        ├── chargement_rh_1_preparer.sql # fourni
        ├── chargement_rh_2_copier.sql   # fourni
        ├── 00_tables_rh.sql             # fourni
        ├── staging/                     # 2 vues fournies
        ├── marts/                       # 3 transformations fournies
        ├── catalogue/                   # fiches SQL + vue V_CATALOGUE
        ├── controles/                   # licence_unique fournie + contrôles ajoutés
        ├── purge_rh.sql
        ├── conservation_rh.sql
        └── taches_rh.sql
```

Les noms des nouveaux fichiers présentés ici suivent le guide ; inspecter les fichiers du kit avant de créer des doublons. Les documents de modèles restent dans `docs/` si le kit les contient.

### Sécurité Git avant le premier commit

- Vérifier `.gitignore` et exclure explicitement `data/drivers.csv`, `data/driver_shifts.csv` et tout secret ; préférer une exclusion de `data/*.csv` si adaptée.
- Contrôler `git status --short` et `git ls-files data/` **avant** `git add`, `git commit`, `git push`.
- Ne jamais publier les CSV **même fictifs**, ni captures avec valeurs personnelles, tokens, identifiants ou URL sensibles.
- Si un CSV a déjà été publié, ne pas croire qu'une simple suppression du fichier efface son historique : arrêter la publication et traiter l'historique selon la procédure adaptée.

---

## 8. Séquence d'exécution et critères de validation

### Phase 0 — Préparer (avant jour 1)

- [ ] Créer le dépôt GitHub public **vide** `hudson-cab-gouvernance` ; récupérer le **starter-kit** selon l'étape 0 du guide.
- [ ] Lire le contrat, le guide et les scripts déjà fournis.
- [ ] Vérifier que le compte Snowflake est **Enterprise**.
- [ ] Exécuter `snowflake/00_installation.sql` **avec `ACCOUNTADMIN`**.
- [ ] Vérifier `NYC_TAXI`, `NYC_TAXI_WH`, `RAW`, `STAGING`, `MARTS`, `TRANSFORMER`.
- [ ] Ne publier aucun fichier avant vérification du `.gitignore` (jour 1, étape 7).

### Jour 1 matin — Inventaire et droit applicable

- [ ] Lire `exemples/FICHE_JURIDIQUE.md` ; reprendre les modèles de `docs/`.
- [ ] Inventorier toutes les colonnes des deux CSV et leur caractère personnel / identifiable, y compris les identifiants indirects.
- [ ] Vérifier le RGPD et les rôles juridiques à partir des articles officiels ; noter la région Snowflake.
- [ ] Configurer au moins 3 sources officielles pour la veille et conserver une capture.
- [ ] Rédiger 4 fiches ; confronter toutes les clauses du contrat au droit ; consigner les écarts dans `README.md`.

**Sortie attendue :** première version des `docs/VEILLE.md` et `docs/REGISTRE.md`, traçabilité des sources.

### Jour 1 après-midi — Ingestion, schéma de gouvernance et catalogue

**Ordre exact des scripts fournis, en utilisant `TRANSFORMER` après l'installation :**

1. `snowflake/rh/chargement_rh_1_preparer.sql` ; stage `RH_STAGE` créé.
2. Déposer les **deux fichiers** depuis Snowsight ; `LIST @NYC_TAXI.RAW.RH_STAGE` renvoie 2 fichiers.
3. `snowflake/rh/chargement_rh_2_copier.sql` ; contrôler **400 / 25 951**, puis **0 fichier** dans le stage. Rejouer le chargement pour vérifier l'absence de doublons.
4. `snowflake/rh/00_tables_rh.sql`.
5. `snowflake/rh/staging/stg_rh__drivers.sql`, puis `stg_rh__driver_shifts.sql`.
6. `snowflake/rh/marts/dim_depot.sql`, puis `dim_driver.sql`, puis `mart_driver_monthly.sql` ; contrôler **3 / 400 / 914**, et **25 933** côté vue staging des services.
7. Avec rôles indiqués dans le guide : créer `gouvernance/01_gouvernance.sql` (délégations via `ACCOUNTADMIN`, objets par `GOUVERNANCE`).
8. Faire tourner le modèle de fiche `DIM_DEPOT`, puis créer les fiches SQL des quatre tables RH avec `TRANSFORMER`.

- [ ] Vérifier que les CSV sont ignorés **avant tout commit**.
- [ ] Vérifier 3 tags, commentaires utiles, types et descriptions.
- [ ] Captures de veille et tags de table.

**Sortie attendue :** RAW et MARTS initialisés, catalogue documenté, gouvernance en place **sans politiques métier encore**.

### Jour 2 — Droits, masquage, filtrage et tests

- [ ] Exécuter les exemples de masking et row access du bac à sable.
- [ ] Créer `02_roles_metier.sql` sous `ACCOUNTADMIN` ; attribuer les permissions minimales.
- [ ] Compléter **d'abord** la matrice des cas attendus dans `docs/ACCES.md`.
- [ ] Décider et justifier masquage / suppression des colonnes MARTS ; traiter `driver_name`, l'exception `driver_id` et l'année de naissance.
- [ ] Créer `03_masquage.sql` via `GOUVERNANCE` ; attention au type de retour des politiques.
- [ ] Créer `04_acces_depot.sql` via `GOUVERNANCE`, y compris les entrées de `TRANSFORMER` et des rôles ayant accès à tous les dépôts.
- [ ] Tester `RH_PAIE`, les deux responsables, `ANALYSTE`, `GOUVERNANCE`, `ACCOUNTADMIN` et un rôle non autorisé si disponible.
- [ ] **Rejouer les transformations** avec `TRANSFORMER` et **retester les protections** ; la paie doit toujours voir les valeurs réelles autorisées.

**Sortie attendue :** tous les cas du cahier de tests sont documentés et réussis, capture d'une même requête sous deux rôles.

### Jour 3 — Purge, qualité, orchestration, audit, démonstration

- [ ] Écrire `rh/purge_rh.sql` ; mesurer le nombre de chauffeurs avant suppression ; purger toutes les copies nécessaires, y compris les services concernés.
- [ ] Prouver Time Travel, puis exécuter `rh/conservation_rh.sql` avec le rôle propriétaire `TRANSFORMER` ; documenter Fail-safe.
- [ ] Vérifier le stage vide.
- [ ] Implémenter au moins 3 contrôles (`licence_unique`, `service_rattache`, un autre) et enregistrer leurs résultats.
- [ ] Écrire `rh/catalogue/...` pour `GOUVERNANCE.V_CATALOGUE` ; tester lecture par `ANALYSTE`.
- [ ] Créer et activer le graphe `T_PURGE` -> `T_QUALITE` -> `T_TABLES`, avec `TRANSFORMER` ; exécuter le graphe.
- [ ] Prouver la **réussite** normale **et l'arrêt** volontaire de `T_TABLES` en cas d'alerte bloquante ; rétablir ensuite le seuil.
- [ ] Revérifier **tags, descriptions, masquages et filtres** après une reconstruction.
- [ ] Écrire `gouvernance/06_audit.sql`, exécuté avec `ACCOUNTADMIN` ; croiser `ACCESS_HISTORY` et `QUERY_HISTORY` par `query_id` pour identifier utilisateurs **et rôles**.
- [ ] Captures : lignage, tâches, `QUALITE_RESULTATS`, audit ; finaliser `REGISTRE.md` et `README.md`.
- [ ] **Suspendre la tâche racine** après la démonstration pour éviter des coûts non désirés.

**Sortie attendue :** preuves de fonctionnement de bout en bout et présentation de 15 minutes maximum : ~5 minutes veille, ~10 minutes gouvernance.

---

## 9. Cahier de tests minimal à faire compléter par Codex

À **écrire avant** le code des politiques dans `docs/ACCES.md`, puis remplir avec observation réelle :

| ID | Rôle / scénario | Attendu | Observé | État | Preuve |
|---|---|---|---|---|---|
| A01 | `RH_PAIE` sur `DIM_DRIVER` | Tous les dépôts ; valeurs personnelles autorisées en clair | À renseigner | ☐ | Capture / SQL |
| A02 | `RESP_DEPOT_QUEENS` | Exclusivement Queens ; nom/prénom/téléphone en clair ; autres données protégées | À renseigner | ☐ | Capture / SQL |
| A03 | `RESP_DEPOT_BRONX` | Exclusivement Bronx ; idem | À renseigner | ☐ | Capture / SQL |
| A04 | `ANALYSTE` | Tous les dépôts ; pas d'identification directe ; année de naissance seule | À renseigner | ☐ | Capture / SQL |
| A05 | `GOUVERNANCE` | Aucune ligne / aucune donnée personnelle | À renseigner | ☐ | Erreur ou 0 ligne expliqués |
| A06 | `ACCOUNTADMIN` | Aucune ligne RH exploitable | À renseigner | ☐ | Erreur ou 0 ligne expliqués |
| A07 | Rôle non autorisé | Aucune ligne RH | À renseigner | ☐ | SQL |
| A08 | Tous les rôles métier | `driver_id` disponible ; `DIM_DEPOT` non filtrée | À renseigner | ☐ | SQL |
| A09 | Après reconstruction avec `TRANSFORMER` | Masquages / row access / tags / commentaires préservés | À renseigner | ☐ | SQL |
| A10 | Mise à jour `ACCES_DEPOT` | Nouveau dépôt attribué **sans modifier la politique** | À renseigner | ☐ | SQL |
| P01 | Chargement répété | Pas de doublons ; stage vide | À renseigner | ☐ | Compteurs + LIST |
| R01 | Purge | Plus aucun chauffeur hors rétention dans les copies concernées | À renseigner | ☐ | Compteurs avant/après |
| R02 | Time Travel | Rétention configurée à 1 jour ; limites Fail-safe expliquées | À renseigner | ☐ | SHOW + requête |
| Q01 | Qualité nominale | Résultats historisés ; chaîne aboutit à `T_TABLES` | À renseigner | ☐ | TASK_HISTORY |
| Q02 | Qualité bloquante | `service_rattache` dépasse 50 : pas de `T_TABLES` | À renseigner | ☐ | TASK_HISTORY |
| AU1 | Audit | Lectures de `DIM_DRIVER` avec utilisateur, rôle, date / requête | À renseigner | ☐ | SQL + résultat |

**Attention :** les compteurs par dépôt, après application des filtres, sont à mesurer sur le vrai jeu de test ; **ne pas en inventer**. Une requête peut échouer pour permissions insuffisantes et satisfaire un « accès refusé », mais il faut le distinguer clairement d'un filtre qui retourne 0 ligne.

### Quelques requêtes d'observation (à adapter au bon rôle)

```sql
-- Volumes de référence : à exécuter avec TRANSFORMER.
SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS;
SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS;
SELECT COUNT(*) FROM NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS;
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;
SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
LIST @NYC_TAXI.RAW.RH_STAGE;

-- Vérifier les objets de gouvernance avec un rôle habilité.
SHOW TAGS IN SCHEMA NYC_TAXI.GOUVERNANCE;
SHOW MASKING POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;
SHOW ROW ACCESS POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;
SELECT * FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT;

-- Contrôler l'attachement des politiques sur la dimension RH.
SELECT policy_name, policy_kind, ref_entity_name, ref_column_name, tag_name
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER',
    REF_ENTITY_DOMAIN => 'TABLE'
));
```

---

## 10. Points de vigilance et décisions à tracer

| Sujet | Risque | Décision / action attendue |
|---|---|---|
| RGPD / transferts | Conclure trop vite à une exemption ou conformité | Analyse juridique sourcée, éventuels écarts au contrat |
| Public GitHub | CSV ou secrets dans l'historique | `.gitignore`, revue des fichiers avant commit |
| `ACCOUNTADMIN` | Héritage de droits ; masquage non testé | Tests isolés ; aucune exception implicite |
| `TRANSFORMER` | Lecture masquée contaminant MARTS | Dérogations strictement nécessaires au pipeline + tests de reconstruction |
| `driver_id` | Masquage par tag trop large | Exception explicite pour identifiant interne, rôles métier |
| `driver_name` | Colonne dérivée oubliée | Classification et masquage sur MARTS |
| Dépôts | Politique codée en dur | Table `ACCES_DEPOT` modifiable indépendamment |
| `CREATE OR REPLACE TABLE` | Perte de politiques / commentaires / tags | Conserver l'identité des tables ; utiliser `INSERT OVERWRITE` fourni |
| SQL rejouable | Création de policy attachée échouant au second run | Gestion de l'état existant, `ALTER ... SET BODY` lorsque nécessaire |
| Purge | Orphelins dans `DRIVER_SHIFTS` et recréation en MARTS | Ordre / contrôles avant-après / purge exhaustive |
| Rétention | Time Travel et Fail-safe confondus | Rétention 1 jour + description Fail-safe 7 jours |
| Audit | Confusion entre utilisateur et rôle ; délai d'alimentation | Jointure `ACCESS_HISTORY` / `QUERY_HISTORY`, latence possible jusqu'à ~3 h |
| Tâches | Crédits consommés après exercice | Suspendre `T_PURGE` une fois la démo terminée |

### Journal des décisions (`PROPOSÉ`)

À tenir dans `README.md` ou un fichier dédié, avec : **date, choix, source de l'exigence, alternatives, justification, impact sur droits/conservation/tests, approbation du binôme**. Ne jamais confondre une recommandation de Codex avec une obligation du contrat.

---

## 11. Livrables et définition de terminé

- [ ] **Dépôt public** `hudson-cab-gouvernance`, sans données RH ni secrets.
- [ ] **`README.md`** : présentation, prérequis, installation, ordre des scripts, section « Gouvernance », décisions, écarts juridiques, limites, preuves.
- [ ] **`snowflake/gouvernance/`** : schéma, tags, rôles, droits, masking, row access, correspondance, audit — scripts rejouables.
- [ ] **`snowflake/rh/`** : ingestion, transformations, catalogue, contrôles, purge, conservation, tâches.
- [ ] **`docs/VEILLE.md`** : droit applicable, veille active, 4 fiches, écart contrat/textes.
- [ ] **`docs/REGISTRE.md`** : inventaire des données et registre avec justificatifs.
- [ ] **`docs/ACCES.md`** : matrice des droits, tests *attendus* puis *observés*, preuves de toutes les catégories de rôle.
- [ ] **Captures documentées** : outil de veille, tags, tests rôles, lignage, tâches, qualité, audit.
- [ ] **Tests de robustesse** : scripts de chargement et de transformation rejoués ; protections préservées.
- [ ] **Présentation** : 15 min au plus, 5 min veille / 10 min gouvernance en démonstration.

### Correspondance des critères d'évaluation

- **C4 — Veille technique et réglementaire :** justification par article précis, 3 sources et outil réel, 4 fiches, confrontation exhaustive du contrat.
- **C19 — Composants d'infrastructure :** ingestion des deux CSV, stage vidé, tâches en chaîne, protections persistantes, scripts documentés et sûrs pour Git.
- **C20 — Catalogue :** commentaires, tags personnels y compris dérivés, `V_CATALOGUE`, règles de qualité documentées, lignage.
- **C21 — Gouvernance :** matrice d'accès prouvée, correspondance dépôt extensible, purge 5 ans, Time Travel 1 jour, qualité bloquante, audit et registre.

---

## 12. Prompt de démarrage prêt à donner à Codex

> Tu interviens comme assistant Data Engineer Snowflake sur le projet `hudson-cab-gouvernance`. Lis **d'abord** `GUIDELINE_PROJET_HUDSON_CAB.md`, `CONTRAT_GOUVERNANCE.md` et `GUIDE_BRIEF_GOUVERNANCE.md`, puis examine l'arborescence et les SQL présents. Le contrat prévaut sur les propositions du guide de cadrage.  
> **Première réponse uniquement :** (1) inventaire du contenu existant / manquant, (2) dépendances et ordre d'exécution, (3) plan d'implémentation par phases, (4) risques et questions réellement bloquantes. **Ne génère pas tout le projet d'un coup.**  
> Ensuite, travaille **étape par étape** : pour chaque fichier produit, donne la finalité, le rôle Snowflake, le SQL complet ou diff ciblé, le test écrit avant la politique, la validation attendue et les limites. Respecte strictement les noms d'objets et la matrice du contrat. N'invente pas de résultats d'exécution, ne publie ni CSV RH ni secrets, et évite toute reconstruction qui efface les politiques/tags. Les validations réelles seront effectuées dans Snowsight et consignées par nous.

### Exemple de première mission ciblée à Codex

> « Analyse l'étape 0 et les scripts fournis ; produis une checklist d'installation et des requêtes de vérification. **N'effectue pas de modification** tant que tu n'as pas vérifié le kit. »

Puis enchaîner sur le jour 1, le jour 2 et le jour 3 en demandant une seule livraison cohérente à la fois.

---

## 13. Références du projet

- [Brief complet — dépôt de formation](https://github.com/gsoulat/formation-data-IA/tree/main/99-Brief/Data-Engineer/Snowflake/Snowflake%2BGouvernance)
- [Guide officiel étape par étape](https://github.com/gsoulat/formation-data-IA/blob/main/99-Brief/Data-Engineer/Snowflake/Snowflake%2BGouvernance/starter-kit/GUIDE_BRIEF_GOUVERNANCE.md)
- [Contrat de gouvernance — référence contractuelle](https://github.com/gsoulat/formation-data-IA/blob/main/99-Brief/Data-Engineer/Snowflake/Snowflake%2BGouvernance/starter-kit/CONTRAT_GOUVERNANCE.md)
- [Exemples pédagogiques](https://github.com/gsoulat/formation-data-IA/tree/main/99-Brief/Data-Engineer/Snowflake/Snowflake%2BGouvernance/starter-kit/exemples)
- [Ressources pédagogiques](https://github.com/gsoulat/formation-data-IA/blob/main/99-Brief/Data-Engineer/Snowflake/Snowflake%2BGouvernance/RESSOURCES.md)

**Dernière règle :** toutes les validations marquées « attendu » restent hypothétiques jusqu'à observation réelle dans Snowflake ; consigner les écarts sans masquer les erreurs.
