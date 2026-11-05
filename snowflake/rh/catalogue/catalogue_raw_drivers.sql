-- Fiche complète : NYC_TAXI.RAW.DRIVERS
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

COMMENT ON TABLE NYC_TAXI.RAW.DRIVERS IS
  'Copie fidèle du fichier RH drivers.csv : 1 ligne = 1 chauffeur fictif. Chargement à réception du fichier RH. Source : Hudson Cab Partners. Responsable technique : équipe data.';

COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.driver_id          IS 'Identifiant interne stable du chauffeur, utilisé pour les jointures et comptages.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.first_name         IS 'Prénom déclaré du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.last_name          IS 'Nom de famille déclaré du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.email              IS 'Adresse électronique professionnelle ou de contact du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.phone              IS 'Numéro de téléphone de contact du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.birth_date         IS 'Date de naissance complète du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.tlc_license_number IS 'Numéro de licence professionnelle délivré par la Taxi and Limousine Commission.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.depot              IS 'Dépôt de rattachement indiqué dans le fichier source.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.hire_date          IS 'Date de début du contrat ou de l''activité du chauffeur.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS.end_date           IS 'Date de fin du contrat ; NULL signifie que le chauffeur est en poste.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS._source_file       IS 'Nom du fichier chargé dans Snowflake, fourni par la métadonnée de copie.';
COMMENT ON COLUMN NYC_TAXI.RAW.DRIVERS._loaded_at         IS 'Horodatage technique du début de lecture du fichier par COPY INTO.';

ALTER TABLE NYC_TAXI.RAW.DRIVERS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat du chauffeur';

ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN driver_id          SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN first_name         SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN last_name          SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'nom';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN email              SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'email';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN phone              SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'telephone';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN birth_date         SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'date_naissance';
ALTER TABLE NYC_TAXI.RAW.DRIVERS MODIFY COLUMN tlc_license_number SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_officiel';

SELECT column_name, comment
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'RAW' AND table_name = 'DRIVERS'
ORDER BY ordinal_position;

