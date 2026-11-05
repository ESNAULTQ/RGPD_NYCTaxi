-- Fiche courte : NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

COMMENT ON TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY IS
  'Activité mensuelle par chauffeur et dépôt : nombre de services, heures, courses et recettes. Sources : STAGING.STG_RH__DRIVER_SHIFTS et MARTS.DIM_DRIVER. Reconstruction quotidienne après qualité.';

ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat du chauffeur';

ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_id   SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY MODIFY COLUMN driver_name SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';

-- Les agrégats restent rattachables à une personne par driver_id ; l'absence
-- de catégorie de tag « donnée professionnelle » est documentée dans le registre.
SELECT level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
  'NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'table'));

