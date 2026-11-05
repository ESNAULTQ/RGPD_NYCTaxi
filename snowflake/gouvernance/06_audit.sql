-- =====================================================================
-- 06_audit.sql — qui a lu MARTS.DIM_DRIVER ces sept derniers jours ?
-- Exécuter avec ACCOUNTADMIN. ACCESS_HISTORY exige Enterprise et peut avoir
-- jusqu'à environ 3 heures de retard ; QUERY_HISTORY jusqu'à environ 45 min.
-- La requête n'affiche aucune valeur RH.
-- =====================================================================

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
)
SELECT DISTINCT
  a.query_start_time,
  a.user_name,
  q.role_name,
  a.object_name,
  a.query_id
FROM acces_dim_driver a
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY q
  ON q.query_id = a.query_id
ORDER BY a.query_start_time DESC;

-- Contrôle de fraîcheur : si la requête précédente est vide juste après
-- les tests, attendre jusqu'à trois heures puis la relancer.
SELECT
  MAX(query_start_time) AS dernier_evenement_access_history,
  DATEDIFF(minute, MAX(query_start_time), CURRENT_TIMESTAMP()) AS retard_minutes_indicatif
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY;
