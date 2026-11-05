# Les accès — carte des droits et cahier de tests

> La partie 1 décrit la cible préparée au jour 1. La partie 2 fige les attendus du jour 2 **avant** l'exécution des politiques. Les tests ont été exécutés avant la purge ; toutes les grilles détaillées n'ont pas été conservées. Leur conformité a été reconfirmée par le responsable du projet le 5 novembre 2026 et les preuves agrégées post-purge sont liées ci-dessous, sans valeur RH.

## Partie 1 — Carte des droits

### Propriété cible des objets

| Objet | Propriétaire cible | Créé par |
|---|---|---|
| Tables `RAW`, vues `STAGING`, tables `MARTS` | `TRANSFORMER` | Scripts d'ingestion et de transformation |
| Schéma `GOUVERNANCE` | `GOUVERNANCE` | `01_gouvernance.sql` avec transfert de propriété |
| Tags | `GOUVERNANCE` | `01_gouvernance.sql` |
| Politiques de masquage | `GOUVERNANCE` | Jour 2 |
| Politique d'accès par ligne | `GOUVERNANCE` | Jour 2 |
| `GOUVERNANCE.ACCES_DEPOT` | `GOUVERNANCE` | Jour 2 |
| `GOUVERNANCE.QUALITE_RESULTATS` | `GOUVERNANCE` | `01_gouvernance.sql` |
| `GOUVERNANCE.V_CATALOGUE` | `TRANSFORMER` | Jour 3, grâce à `CREATE VIEW` délégué |

### Actions et privilèges

| Action | Rôle | Privilège ou propriété nécessaire | Accordé par |
|---|---|---|---|
| Créer les tags | `GOUVERNANCE` | Propriété du schéma `GOUVERNANCE` | `ACCOUNTADMIN` transfère le schéma |
| Poser un tag sur `DIM_DRIVER` | `TRANSFORMER` | Propriété de la table, `USAGE` sur le schéma du tag, `APPLY` sur le tag | `GOUVERNANCE` pour le tag |
| Créer une politique de masquage | `GOUVERNANCE` | Propriété du schéma | Propriété |
| Attacher une politique de masquage à un tag | `GOUVERNANCE` | Propriété du tag et droit global `APPLY MASKING POLICY` | `ACCOUNTADMIN` |
| Ajouter une politique d'accès par ligne à une table MARTS | `GOUVERNANCE` | `USAGE` sur MARTS et droit global `APPLY ROW ACCESS POLICY` | `ACCOUNTADMIN` |
| Écrire dans `QUALITE_RESULTATS` | `TRANSFORMER` | `INSERT` et `SELECT` | `GOUVERNANCE` |
| Créer `V_CATALOGUE` dans `GOUVERNANCE` | `TRANSFORMER` | `USAGE`, `CREATE VIEW` | `GOUVERNANCE` |
| Lire `DIM_DRIVER` | Rôles métier au jour 2 | `USAGE` base/schéma, `SELECT` table | `ACCOUNTADMIN`/propriétaire selon le script |
| Exécuter une requête | Chaque rôle | `USAGE` sur `NYC_TAXI_WH` | `ACCOUNTADMIN` |
| Lancer les tâches | `TRANSFORMER` | `EXECUTE TASK` sur le compte et `CREATE TASK` sur MARTS | `ACCOUNTADMIN` |

### Séparation des responsabilités

- `GOUVERNANCE` reçoit `USAGE` sur les schémas nécessaires pour trouver les objets et y attacher des règles, mais aucun `SELECT` sur les données RH.
- `TRANSFORMER` voit les valeurs nécessaires au pipeline afin de ne jamais recopier une valeur masquée dans les MARTS.
- Les rôles métier ne liront que `MARTS` et la vue de catalogue.
- `ACCOUNTADMIN` et `SYSADMIN` ne constituent pas des exceptions implicites aux politiques.

### Ce que les rôles pourraient défaire

| Rôle | Risque | Mesure attendue |
|---|---|---|
| `GOUVERNANCE` | Modifier/détacher une politique ou changer un tag | Audit des changements, séparation avec la lecture RH |
| `TRANSFORMER` | Retirer un tag d'une table qu'il possède ou reconstruire incorrectement les données | Scripts versionnés, tests après reconstruction, audit DDL |
| `ACCOUNTADMIN` | Modifier les privilèges ou la hiérarchie des rôles | Usage exceptionnel et audité ; tests isolés sans rôle secondaire |

## Partie 2 — Cahier de tests du jour 2

Pour chaque scénario :

```sql
USE SECONDARY ROLES NONE;
USE ROLE <ROLE_TESTE>;
USE WAREHOUSE NYC_TAXI_WH;
```

Les compteurs ci-dessous sont calculés à partir des deux CSV locaux et des transformations fournies. Ils doivent encore être confirmés sous chaque rôle dans Snowflake.

### Décisions de masquage prises avant les politiques

| Type / donnée | Représentation protégée | Justification |
|---|---|---|
| Texte personnel | `*****` | Ne conserve ni préfixe ni domaine permettant une recherche ciblée |
| Date de naissance pour un rôle non autorisé | `NULL` | Aucune composante réelle exposée |
| Date de naissance pour `ANALYSTE` | `AAAA-01-01` | Snowflake impose un retour de type `DATE` ; seul `AAAA` est réel, mois et jour sont synthétiques |
| `driver_id` | Visible pour les quatre rôles métier | Exception contractuelle nécessaire aux jointures et comptages |
| `driver_name` | Même règle que les noms source | Donnée dérivée toujours identifiante |

Les colonnes professionnelles non directement identifiantes (`depot`, dates d'emploi, statut, ancienneté et mesures d'activité) restent visibles dans les lignes autorisées. La taxonomie contractuelle du tag ne fournit pas de catégorie dédiée à ces données.

### Lignes visibles

| ID | Rôle/scénario | Attendu avant mesure | Observé | État |
|---|---|---|---|---|
| A01 | `RH_PAIE` sur `DIM_DRIVER` | 400 lignes ; Bronx 122, Brooklyn 117, Queens 161 | Conforme avant purge ; non-régression du 5 novembre : 354 lignes et aucun masque métier (`03a_acces_rh_paie.png`) | ☑ |
| A02 | `RESP_DEPOT_QUEENS` sur `DIM_DRIVER` | 161 lignes, exclusivement Queens | Conforme avant purge ; exécution reconfirmée le 5 novembre, grille détaillée non conservée | ☑ |
| A03 | `RESP_DEPOT_BRONX` sur `DIM_DRIVER` | 122 lignes, exclusivement Bronx | Conforme avant purge ; exécution reconfirmée le 5 novembre, grille détaillée non conservée | ☑ |
| A04 | `RESP_DEPOT_QUEENS` sur le MART mensuel | 365 lignes, exclusivement Queens | Conforme avant purge ; exécution reconfirmée le 5 novembre, grille détaillée non conservée | ☑ |
| A05 | `RESP_DEPOT_BRONX` sur le MART mensuel | 290 lignes, exclusivement Bronx | Conforme avant purge ; exécution reconfirmée le 5 novembre, grille détaillée non conservée | ☑ |
| A06 | `ANALYSTE` | 400 chauffeurs et 914 lignes mensuelles, tous dépôts | Conforme avant purge ; non-régression du 5 novembre : 354 lignes, identifiants directs masqués (`03b_acces_analyste.png`) | ☑ |
| A07 | `GOUVERNANCE` | Accès refusé : aucun `SELECT` RH accordé | Erreur `does not exist or not authorized` observée | ☑ |
| A08 | `ACCOUNTADMIN` | 0 ligne sur les quatre tables RH protégées | 0 ligne observée lors du test du jour 2 ; reconfirmé le 5 novembre | ☑ |
| A09 | `PUBLIC`, rôle absent de la matrice | Accès refusé | Refus intentionnel observé dans `verification_jour2_refus.sql` | ☑ |
| A10 | Tous rôles métier sur `DIM_DEPOT` | 3 dépôts, sans filtre | 3 dépôts observés lors des tests du jour 2 | ☑ |

### Valeurs visibles

Le chauffeur de test `D0003` est rattaché à Queens. Aucune valeur personnelle réelle n'est inscrite dans ce document public.

| Donnée | `RH_PAIE` | `RESP_DEPOT_QUEENS` | `RESP_DEPOT_BRONX` | `ANALYSTE` |
|---|---|---|---|---|
| Ligne de `D0003` | Visible | Visible | Invisible | Visible |
| `driver_id` | `D0003` | `D0003` | Invisible | `D0003` |
| nom/prénom | Valeur réelle | Valeur réelle | Invisible | `*****` |
| téléphone | Valeur réelle | Valeur réelle | Invisible | `*****` |
| e-mail | Valeur réelle | `*****` | Invisible | `*****` |
| date de naissance | Date réelle | `NULL` | Invisible | année réelle avec `01-01` synthétique |
| licence TLC | Valeur réelle | `*****` | Invisible | `*****` |
| `driver_name` mensuel | Valeur réelle | Valeur réelle | Invisible | `*****` |

### Robustesse du pipeline

| ID | Vérification | Attendu | Observé | État |
|---|---|---|---|---|
| P01 | Chargement rejoué | Aucun doublon, stage vide | Aucun doublon observé ; stage vide aux jours 1 et 3 | ☑ |
| P02 | Transformations rejouées avec `TRANSFORMER` | Volumes attendus, valeurs RH réelles pour la paie | Transformations et graphe rejoués ; trois tâches réussies, puis non-régression `RH_PAIE` confirmée | ☑ |
| P03 | Politiques/tags/commentaires après reconstruction | Toujours attachés | Tags et politiques visibles après `INSERT OVERWRITE` ; masquage effectif sur 354 lignes (`02_tags_dim_driver.png`, `03b_acces_analyste.png`) | ☑ |
| P04 | Ajout d'un dépôt à `ACCES_DEPOT` | Accès modifié sans changer la politique | Test temporaire conforme signalé ; ligne Brooklyn retirée après essai, confirmation du responsable le 5 novembre | ☑ |

### Décision d'accès par dépôt

`ACCES_DEPOT` utilise `*` pour les rôles qui doivent voir toutes les valeurs de dépôt, y compris une valeur inconnue à détecter par la qualité. Les responsables disposent d'une ligne avec leur dépôt exact. `GOUVERNANCE`, `ACCOUNTADMIN` et les rôles absents n'ont aucune entrée.

### Preuves anonymisées conservées

- [`03a_acces_rh_paie.png`](03a_acces_rh_paie.png) : 354 lignes après purge, aucun compteur de masque sous `RH_PAIE` ;
- [`03b_acces_analyste.png`](03b_acces_analyste.png) : 354 lignes après purge, noms/e-mails/licences masqués, 342 téléphones masqués et 12 NULL ;
- [`02_tags_dim_driver.png`](02_tags_dim_driver.png) : tags de table, tags de colonnes et politiques visibles ;
- [`07_audit_acces.png`](07_audit_acces.png) : accès pseudonymisés observés sous `ACCOUNTADMIN`, `ANALYSTE`, responsables de dépôt, `RH_PAIE` et `TRANSFORMER`.
