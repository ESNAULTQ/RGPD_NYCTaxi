# Registre du traitement — données du personnel

> Inventaire préparé au jour 1 à partir des schémas CSV et SQL. Les exemples sont des formats fictifs, pas des valeurs recopiées du fichier. Les mesures du jour 3 sont préparées mais restent à confirmer dans Snowsight.

## Partie 1 — Inventaire des données personnelles

### `drivers.csv`

| Colonne | Exemple de format | Qualification | Tag contractuel | Besoin métier principal |
|---|---|---|---|---|
| `driver_id` | `Dxxxx` | Identifiant direct interne | `identifiant_interne` | Jointures, comptages, suivi RH |
| `first_name` | prénom fictif | Identifiant direct | `nom` | Paie et responsables de dépôt |
| `last_name` | nom fictif | Identifiant direct | `nom` | Paie et responsables de dépôt |
| `email` | `prenom.nom@exemple.test` | Identifiant direct | `email` | Contact administratif par la paie |
| `phone` | numéro fictif | Identifiant direct | `telephone` | Contact opérationnel par la paie et le dépôt |
| `birth_date` | `AAAA-MM-JJ` | Identifiant indirect, donnée d'état civil | `date_naissance` | Administration RH ; année seulement pour l'analyse |
| `tlc_license_number` | numéro TLC fictif | Identifiant officiel | `identifiant_officiel` | Vérification de l'autorisation professionnelle |
| `depot` | Bronx/Brooklyn/Queens | Donnée personnelle indirecte/professionnelle | Aucune valeur adaptée dans le contrat | Affectation et filtrage des lignes |
| `hire_date` | `AAAA-MM-JJ` | Donnée personnelle indirecte/professionnelle | Aucune valeur adaptée dans le contrat | Ancienneté et gestion du contrat |
| `end_date` | date ou vide | Donnée personnelle indirecte/professionnelle | Aucune valeur adaptée dans le contrat | Statut d'emploi et purge à cinq ans |

Les colonnes techniques ajoutées dans RAW, `_source_file` et `_loaded_at`, décrivent le chargement plutôt que la personne. Elles peuvent néanmoins faciliter un audit ou révéler un nom de fichier : elles ne doivent pas contenir de secret.

### `driver_shifts.csv`

| Colonne | Exemple de format | Qualification | Tag contractuel | Besoin métier principal |
|---|---|---|---|---|
| `shift_id` | `Sxxxxxx` | Identifiant indirect d'un service rattaché à une personne | `identifiant_interne` | Déduplication et traçabilité du service |
| `driver_id` | `Dxxxx` | Identifiant direct interne | `identifiant_interne` | Rattachement du service au chauffeur |
| `shift_date` | `AAAA-MM-JJ` | Donnée personnelle indirecte/professionnelle | Aucune valeur adaptée dans le contrat | Agrégation mensuelle et activité |
| `depot` | Bronx/Brooklyn/Queens | Donnée personnelle indirecte/professionnelle | Aucune valeur adaptée dans le contrat | Affectation et filtrage par dépôt |
| `start_hour` | entier de 0 à 23 | Donnée personnelle indirecte/professionnelle | Aucune valeur adaptée dans le contrat | Analyse des services |
| `hours_worked` | nombre décimal | Donnée personnelle professionnelle | Aucune valeur adaptée dans le contrat | Temps de travail et agrégats |
| `trips_count` | entier | Donnée personnelle professionnelle | Aucune valeur adaptée dans le contrat | Mesure d'activité |
| `revenue_usd` | montant décimal | Donnée personnelle professionnelle | Aucune valeur adaptée dans le contrat | Analyse économique de l'activité |

Les colonnes techniques `_source_file` et `_loaded_at` ajoutées en RAW ne proviennent pas du CSV et ne sont pas classées comme données personnelles dans cet inventaire.

### Où les données sont copiées ou dérivées

| Origine | Table ou vue | Colonne | Forme |
|---|---|---|---|
| `drivers.driver_id` | `RAW.DRIVERS`, `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `driver_id` | Copie ; sert aussi aux jointures |
| `drivers.driver_id` / `driver_shifts.driver_id` | `MARTS.MART_DRIVER_MONTHLY` | `driver_id` | Clé de regroupement mensuel |
| `first_name`, `last_name` | `RAW.DRIVERS`, `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | mêmes noms | Copie, avec nettoyage léger en STAGING |
| `first_name`, `last_name` | `MARTS.MART_DRIVER_MONTHLY` | `driver_name` | Concaténation dérivée, toujours personnelle |
| `email`, `phone` | `RAW.DRIVERS`, `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | mêmes noms | Normalisation puis copie |
| `birth_date` | `RAW.DRIVERS`, `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `birth_date` | Typage en date puis copie |
| `tlc_license_number` | `RAW.DRIVERS`, `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | même nom | Copie |
| `drivers.depot` | `RAW.DRIVERS`, `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | `depot` | Normalisation puis copie ; colonne de filtrage |
| `hire_date`, `end_date` | `RAW.DRIVERS`, `STAGING.STG_RH__DRIVERS`, `MARTS.DIM_DRIVER` | mêmes noms | Typage puis copie |
| `hire_date`, `end_date` | `MARTS.DIM_DRIVER` | `is_active`, `tenure_years` | Données professionnelles dérivées |
| `shift_id` | `RAW.DRIVER_SHIFTS`, `STAGING.STG_RH__DRIVER_SHIFTS` | `shift_id` | Copie ; déduplication en STAGING |
| données de service | `RAW.DRIVER_SHIFTS`, `STAGING.STG_RH__DRIVER_SHIFTS` | mêmes noms | Typage et normalisation |
| date et mesures de service | `MARTS.MART_DRIVER_MONTHLY` | `activity_month`, `nb_shifts`, `hours_worked`, `trips_count`, `revenue_usd` | Agrégats mensuels par chauffeur et dépôt |

### Constats de l'inventaire

1. `driver_name` est dérivé, mais reste un identifiant direct et doit être protégé comme les colonnes de nom d'origine.
2. Les mesures d'activité sont personnelles parce qu'elles sont regroupées par `driver_id`, même si la taxonomie imposée au tag ne fournit aucune valeur pour la catégorie « données professionnelles ».
3. Le numéro TLC peut être public dans un autre contexte ; cela ne justifie pas de l'exposer à tous les rôles de cet entrepôt.

## Partie 2 — Fiche de registre

### Le traitement

| Rubrique | Réponse provisoire |
|---|---|
| Nom | Gestion RH et analyse de l'activité des chauffeurs Hudson Cab |
| Finalités | Paie, administration du personnel, gestion opérationnelle des dépôts, analyse mensuelle pseudonymisée |
| Personnes concernées | Chauffeurs fictifs affectés aux dépôts de Bronx, Brooklyn et Queens |
| Responsable pressenti | Hudson Cab Europe si elle détermine effectivement finalités et moyens — **à confirmer juridiquement** |
| Origine | Fichiers RH internes `drivers.csv` et `driver_shifts.csv` |

### Catégories de données

| Catégorie | Colonnes principales | Emplacements |
|---|---|---|
| Identité et identifiants | `driver_id`, noms, `birth_date`, licence TLC | RAW, STAGING, `DIM_DRIVER`, nom dérivé dans le MART mensuel |
| Coordonnées | `email`, `phone` | RAW, STAGING, `DIM_DRIVER` |
| Vie professionnelle | dépôt, dates d'emploi, services, heures, courses, recettes | RAW, STAGING et MARTS |
| Métadonnées techniques | fichier source, date de chargement | RAW et vues STAGING |

### Destinataires prévus

| Rôle | Accès prévu | Justification |
|---|---|---|
| `RH_PAIE` | Tous dépôts et données autorisées en clair | Gestion de la paie et du dossier RH |
| Responsables de dépôt | Leur dépôt ; nom, prénom et téléphone en clair | Gestion opérationnelle locale |
| `ANALYSTE` | Tous dépôts, sans identifiant direct ; année de naissance seulement | Analyse globale |
| `TRANSFORMER` | Données nécessaires au pipeline | Chargement et transformation |
| `GOUVERNANCE` | Aucune valeur RH | Administration des règles uniquement |

### Conservation et sécurité

| Règle | Mise en œuvre | Preuve à conserver | Observation jour 3 |
|---|---|---|---|
| Suppression cinq ans après la fin du contrat | `purge_rh.sql` et `T_PURGE` suppriment RAW, services et copies MARTS | Comptages avant/après ; aucun chauffeur hors conservation | 46 chauffeurs supprimés ; 354 conservés ; 0 hors conservation ; volumes `354 / 25 951 / 25 933 / 3 / 354 / 914` après reconstruction |
| Time Travel à un jour | `DATA_RETENTION_TIME_IN_DAYS = 1` sur quatre tables personnelles | `INFORMATION_SCHEMA.TABLES` et test historique | État antérieur 400 et état courant 354 prouvés ; rétention 1 observée sur les quatre tables |
| Fail-safe | 7 jours supplémentaires pour les tables permanentes, non configurables et non interrogeables par l'utilisateur | Documentation Snowflake et mention dans le registre | Limite documentée |
| Stage vide | `COPY INTO ... PURGE = TRUE` et contrôle `LIST` | `LIST` sans résultat | Stage vide observé aux jours 1 et 3 |
| Accès minimal | RBAC, masquage par tag et filtre par dépôt | `docs/ACCES.md` et résultats par rôle | Tests du jour 2 signalés conformes ; preuves à consolider |
| Exactitude | Huit contrôles historisés ; seul `service_rattache > 50` bloque | `QUALITE_RESULTATS` et `TASK_HISTORY` | Graphe observé `SUCCEEDED` ; test au seuil temporaire 0 : `T_QUALITE` `FAILED`, aucune exécution de `T_TABLES`, puis seuil 50 restauré et trois nouveaux succès |
| Audit | `ACCESS_HISTORY` aplati et joint à `QUERY_HISTORY` par `query_id` | Capture indiquant utilisateurs et rôles, sans valeur RH | Audit observé avec utilisateur, `SYSTEM`, rôles métier, `TRANSFORMER`, `ACCOUNTADMIN`, objet et query ID ; retard indicatif observé 29 min |

Le catalogue métier `GOUVERNANCE.V_CATALOGUE` a été lu avec `ANALYSTE` : 4 colonnes pour `DIM_DEPOT`, 12 pour `DIM_DRIVER` et 8 pour `MART_DRIVER_MONTHLY`, soit 24 lignes de métadonnées sans valeur RH.

Après reconstruction par `T_TABLES`, un test agrégé sous `ANALYSTE` a confirmé le masquage sans publier de valeur : 354 noms, e-mails et licences masqués, 342 téléphones masqués, 12 téléphones NULL, 354 dates limitées à l'année et aucun `driver_id` masqué.

### Stratégie de rechargement

Un nouveau fichier complet peut réintroduire des chauffeurs déjà arrivés à échéance. L'ordre imposé est donc : chargement RAW, `T_PURGE`, `T_QUALITE`, puis `T_TABLES`. La purge utilise la date courante et ne dépend pas d'une liste historique externe. Les vues STAGING ne stockent rien ; la reconstruction par `INSERT OVERWRITE` ne peut remettre dans MARTS que ce qui subsiste dans RAW après la purge.

### Qualité observée sur le jeu fourni après purge

| Règle | Anomalies observées | Seuil | Effet |
|---|---:|---:|---|
| `licence_unique` | 4 | 0 | Avertissement |
| `telephone_renseigne` | 12 | 14,50 | Conforme |
| `email_valide` | 7 | 0 | Avertissement |
| `dates_coherentes` | 8 | 0 | Avertissement |
| `depot_connu` | 9 | 0 | Avertissement |
| `service_rattache` | 25 | 50 | Conforme ; pipeline autorisé |
| `service_unique` | 18 | 0 | Avertissement |
| `duree_plausible` | 14 | 0 | Avertissement |

### Limites connues

- La base légale, la qualification exacte des entités et les transferts ne peuvent pas être prouvés par le code SQL seul.
- La taxonomie contractuelle du tag ne couvre pas toutes les données professionnelles pourtant personnelles.
- Les observations d'audit, de purge, de Time Travel et des tâches ne seront disponibles qu'après exécution réelle.
- Le Fail-safe n'est pas un mécanisme d'accès ou de restauration autonome : Snowflake seul peut intervenir, sur une base de meilleur effort.
