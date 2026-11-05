-- =====================================================================
-- vue_catalogue.sql — catalogue lisible par les rôles métier
-- Une ligne par colonne des trois tables MARTS du domaine RH.
-- Exécuter avec TRANSFORMER : il voit les tables et a CREATE VIEW dans
-- GOUVERNANCE, sans donner à GOUVERNANCE l'accès aux valeurs RH.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

CREATE OR REPLACE VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE
COMMENT = 'Catalogue des trois tables MARTS du domaine RH : une ligne par colonne, sans valeur RH'
AS
WITH tags AS (
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
      'NYC_TAXI.MARTS.DIM_DEPOT', 'TABLE'))
    UNION ALL
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
      'NYC_TAXI.MARTS.DIM_DRIVER', 'TABLE'))
    UNION ALL
    SELECT object_schema, object_name, column_name, tag_name, tag_value
    FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
      'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'TABLE'))
)
SELECT
    c.table_schema,
    c.table_name,
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.comment AS description,
    MAX(IFF(t.tag_name = 'SENSIBILITE', t.tag_value, NULL)) AS sensibilite,
    MAX(IFF(t.tag_name = 'DUREE_CONSERVATION', t.tag_value, NULL)) AS duree_conservation,
    MAX(IFF(t.tag_name = 'DONNEE_PERSONNELLE', t.tag_value, NULL)) AS donnee_personnelle
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN tags t
  ON t.object_schema = c.table_schema
 AND t.object_name = c.table_name
 AND t.column_name = c.column_name
WHERE c.table_schema = 'MARTS'
  AND c.table_name IN ('DIM_DEPOT', 'DIM_DRIVER', 'MART_DRIVER_MONTHLY')
GROUP BY
    c.table_schema, c.table_name, c.ordinal_position,
    c.column_name, c.data_type, c.comment;

-- Les droits futurs du jour 2 couvrent déjà cette vue. Ces droits explicites
-- rendent le script autonome et n'exposent aucune table de GOUVERNANCE.
GRANT SELECT ON VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE TO ROLE RH_PAIE;
GRANT SELECT ON VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE TO ROLE RESP_DEPOT_QUEENS;
GRANT SELECT ON VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE TO ROLE RESP_DEPOT_BRONX;
GRANT SELECT ON VIEW NYC_TAXI.GOUVERNANCE.V_CATALOGUE TO ROLE ANALYSTE;

-- Propriétaire : 24 lignes attendues (4 + 12 + 8).
SELECT table_name, COUNT(*) AS nb_colonnes
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
GROUP BY table_name
ORDER BY table_name;

-- Test métier : les trois tables doivent rester visibles sans aucune valeur RH.
USE ROLE ANALYSTE;
SELECT table_name, COUNT(*) AS nb_colonnes
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
GROUP BY table_name
ORDER BY table_name;
