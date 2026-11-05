# Jour 2 — rôles, masquage, filtrage et tests

Exécuter les sections dans l'ordre. Les tests de `docs/ACCES.md` ont été écrits avant les politiques. Ne jamais tester avec des rôles secondaires actifs.

## 0. Prérequis

- [x] Les volumes du jour 1 sont `400 / 25 951 / 25 933 / 3 / 400 / 914`.
- [x] Le stage est vide.
- [x] Les trois tags existent et les catalogues sont appliqués.
- [x] Le compte est Enterprise.
- [x] `docs/ACCES.md` a été relu avant le code des politiques.

## 1. Bac à sable

Dans la base d'exemple, exécuter bloc par bloc :

1. `exemples/02_masquage_par_tag.sql`
2. `exemples/03_acces_par_ligne.sql`

Prévoir chaque résultat avant de lancer le test.

## 2. Rôles métier — `ACCOUNTADMIN`

Exécuter `snowflake/gouvernance/02_roles_metier.sql` en entier.

- [x] Les quatre rôles existent et sont attribués à l'utilisateur courant.
- [x] Tous peuvent utiliser `NYC_TAXI_WH`, `NYC_TAXI` et `MARTS`.
- [x] `RH_PAIE` et les responsables n'ont accès qu'aux trois tables prévues.
- [x] `ANALYSTE` dispose de `MARTS` et des futures tables, conformément au contrat.
- [x] Tous peuvent lire les futures vues de catalogue dans `GOUVERNANCE`.

## 3. Masquage — `GOUVERNANCE`

Exécuter `snowflake/gouvernance/03_masquage.sql`.

- [x] Deux politiques existent : texte et date.
- [x] Les deux politiques sont attachées au tag `DONNEE_PERSONNELLE`.
- [x] `TRANSFORMER` et `RH_PAIE` voient les valeurs autorisées en clair.
- [x] Les responsables voient nom, prénom et téléphone en clair.
- [x] `ANALYSTE` ne voit aucun identifiant direct et ne conserve que l'année de naissance.
- [x] `driver_id` reste visible des rôles métier.

## 4. Accès par dépôt — `GOUVERNANCE`

Exécuter `snowflake/gouvernance/04_acces_depot.sql`.

Correspondance attendue :

| Rôle | Dépôt |
|---|---|
| `TRANSFORMER` | `*` |
| `RH_PAIE` | `*` |
| `ANALYSTE` | `*` |
| `RESP_DEPOT_QUEENS` | `Queens` |
| `RESP_DEPOT_BRONX` | `Bronx` |

La politique protège `RAW.DRIVERS`, `RAW.DRIVER_SHIFTS`, `MARTS.DIM_DRIVER` et `MARTS.MART_DRIVER_MONTHLY`. `DIM_DEPOT` n'est pas filtrée.

## 5. Tests par rôle

`snowflake/gouvernance/verification_jour2.sql` peut être rejoué en entier ; il ne contient plus de requête volontairement en erreur. Pour lire clairement les résultats, exécuter de préférence un bloc à la fois et les reporter dans `docs/ACCES.md`.

Les preuves négatives A07 et A09 se trouvent dans `verification_jour2_refus.sql` et doivent être exécutées **un bloc à la fois**. Leur erreur est le résultat attendu.

Avant chaque rôle :

```sql
USE SECONDARY ROLES NONE;
USE ROLE <ROLE>;
USE WAREHOUSE NYC_TAXI_WH;
```

Attendus structurants :

- `RH_PAIE` : 400 chauffeurs, valeurs réelles ;
- Queens : 161 chauffeurs et 365 lignes mensuelles ;
- Bronx : 122 chauffeurs et 290 lignes mensuelles ;
- `ANALYSTE` : 400 et 914, identifiants directs masqués ;
- `GOUVERNANCE` et `PUBLIC` : accès refusé ;
- `ACCOUNTADMIN` : 0 ligne RH ;
- tous les rôles métier : 3 lignes dans `DIM_DEPOT`.

L'erreur attendue de `GOUVERNANCE` doit être conservée comme preuve. Les références de politiques sont inspectées avec `TRANSFORMER`, propriétaire des tables, car `INFORMATION_SCHEMA.POLICY_REFERENCES` exige au moins un privilège sur l'objet inspecté. Ne jamais accorder `SELECT` à `GOUVERNANCE` pour contourner cette règle de visibilité.

## 6. Reconstruction et non-régression

Avec `TRANSFORMER`, rejouer :

1. `snowflake/rh/marts/dim_depot.sql`
2. `snowflake/rh/marts/dim_driver.sql`
3. `snowflake/rh/marts/mart_driver_monthly.sql`

Puis :

- [x] `400 / 914` revérifiés avant purge ; après purge et reconstruction, `354 / 914` observés ;
- [x] accès autorisé de `RH_PAIE` revérifié sans publier l'e-mail réel ;
- [x] références et effet réel des politiques revérifiés ;
- [x] tags et commentaires revérifiés après reconstruction ;
- [x] même requête agrégée capturée sous `RH_PAIE` puis `ANALYSTE`, sans valeur réelle (`03a`/`03b`).

## 7. Extension de la correspondance

Tester l'ouverture temporaire de Brooklyn à la responsable Queens sans modifier la politique :

```sql
USE ROLE GOUVERNANCE;
INSERT INTO NYC_TAXI.GOUVERNANCE.ACCES_DEPOT VALUES ('RESP_DEPOT_QUEENS', 'Brooklyn');

USE ROLE RESP_DEPOT_QUEENS;
SELECT depot, COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot ORDER BY depot;

USE ROLE GOUVERNANCE;
DELETE FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT
WHERE role_name = 'RESP_DEPOT_QUEENS' AND depot = 'Brooklyn';
```

Attendu pendant le test : Queens 161 et Brooklyn 117. Toujours exécuter le `DELETE` de remise en état.

### Critère de sortie

Le jour 2 est terminé lorsque tous les attendus sont comparés aux observations, les reconstructions préservent les contrôles, les preuves sont anonymisées et aucune permission supplémentaire n'a été accordée pour contourner un test.
