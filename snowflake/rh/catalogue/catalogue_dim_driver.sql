-- Fiche complète : NYC_TAXI.MARTS.DIM_DRIVER
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

COMMENT ON TABLE NYC_TAXI.MARTS.DIM_DRIVER IS
  'Dimension RH des chauffeurs : 1 ligne = 1 chauffeur. Source : STAGING.STG_RH__DRIVERS. Reconstruite après purge et contrôles de qualité. Responsable : équipe data RH.';

COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.driver_id          IS 'Identifiant interne stable du chauffeur, visible des rôles métier pour joindre et compter.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.first_name         IS 'Prénom du chauffeur issu de la source RH.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.last_name          IS 'Nom de famille du chauffeur issu de la source RH.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.email              IS 'Adresse électronique normalisée en minuscules.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.phone              IS 'Numéro de téléphone normalisé ; chaîne vide convertie en NULL.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.birth_date         IS 'Date de naissance complète ; l''analyste ne doit accéder qu''à l''année.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tlc_license_number IS 'Numéro de licence professionnelle TLC.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.depot              IS 'Dépôt de rattachement normalisé ; colonne utilisée pour le filtrage des lignes.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.hire_date          IS 'Date de début du contrat ou de l''activité.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.end_date           IS 'Date de fin du contrat ; NULL signifie que le chauffeur est en poste.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.is_active          IS 'Indicateur dérivé : TRUE lorsque la date de fin de contrat est NULL.';
COMMENT ON COLUMN NYC_TAXI.MARTS.DIM_DRIVER.tenure_years       IS 'Ancienneté en années, calculée entre l''embauche et la fin de contrat ou la date courante.';

ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat du chauffeur';

ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN driver_id          SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN first_name         SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN last_name          SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN email              SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'email';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN phone              SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'telephone';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN birth_date         SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER MODIFY COLUMN tlc_license_number SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_officiel';

SELECT column_name, comment
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'MARTS' AND table_name = 'DIM_DRIVER'
ORDER BY ordinal_position;

