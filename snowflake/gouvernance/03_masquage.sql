-- =====================================================================
-- 03_masquage.sql — masquage par tag, un type de politique par type SQL
-- Exécuter avec GOUVERNANCE après 02_roles_metier.sql. Rejouable.
-- Texte protégé : *****. Date analyste : année réelle, mois/jour synthétiques.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_DONNEE_TEXTE
  AS (val STRING) RETURNS STRING -> val
  COMMENT = 'Masque les identifiants texte selon la matrice RH';

ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DONNEE_TEXTE SET BODY ->
  CASE
    WHEN val IS NULL THEN NULL
    -- Le pipeline doit lire les valeurs réelles pour ne pas matérialiser un masque.
    WHEN CURRENT_ROLE() IN ('TRANSFORMER', 'RH_PAIE') THEN val
    -- Exception contractuelle : driver_id reste visible des rôles métier.
    -- Les autres identifiants internes tagués sont en RAW, non lisible par ces rôles.
    WHEN CURRENT_ROLE() IN ('RESP_DEPOT_QUEENS', 'RESP_DEPOT_BRONX', 'ANALYSTE')
         AND SYSTEM$GET_TAG_ON_CURRENT_COLUMN(
               'NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE') = 'identifiant_interne'
      THEN val
    -- Les responsables peuvent nommer et appeler les chauffeurs de leur dépôt.
    WHEN CURRENT_ROLE() IN ('RESP_DEPOT_QUEENS', 'RESP_DEPOT_BRONX')
         AND SYSTEM$GET_TAG_ON_CURRENT_COLUMN(
               'NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE') IN ('nom', 'telephone')
      THEN val
    ELSE '*****'
  END;

CREATE MASKING POLICY IF NOT EXISTS NYC_TAXI.GOUVERNANCE.MASK_DONNEE_DATE
  AS (val DATE) RETURNS DATE -> val
  COMMENT = 'Date complète pour paie/pipeline, année seule pour analyste, NULL sinon';

ALTER MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DONNEE_DATE SET BODY ->
  CASE
    WHEN val IS NULL THEN NULL
    WHEN CURRENT_ROLE() IN ('TRANSFORMER', 'RH_PAIE') THEN val
    WHEN CURRENT_ROLE() = 'ANALYSTE' THEN DATE_FROM_PARTS(YEAR(val), 1, 1)
    ELSE NULL
  END;

-- FORCE rend l'attachement rejouable et ne remplace qu'une politique du même type.
ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE SET
  MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DONNEE_TEXTE FORCE;
ALTER TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE SET
  MASKING POLICY NYC_TAXI.GOUVERNANCE.MASK_DONNEE_DATE FORCE;

SHOW MASKING POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;

SELECT policy_name, policy_kind, ref_entity_name, ref_column_name,
       tag_name, policy_status
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER',
  REF_ENTITY_DOMAIN => 'TABLE'))
ORDER BY ref_column_name, policy_name;

