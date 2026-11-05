-- Fiche courte : NYC_TAXI.RAW.DRIVER_SHIFTS
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

COMMENT ON TABLE NYC_TAXI.RAW.DRIVER_SHIFTS IS
  'Copie fidèle de driver_shifts.csv : 1 ligne = 1 service fictif avant déduplication. Chargement à réception du fichier RH. Source : Hudson Cab Partners.';

ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS SET TAG
  NYC_TAXI.GOUVERNANCE.SENSIBILITE = 'confidentiel',
  NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION = '5 ans après la fin du contrat du chauffeur rattaché';

ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN shift_id  SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS MODIFY COLUMN driver_id SET TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE = 'identifiant_interne';

-- Les dates, dépôts et mesures d'activité restent inventoriés comme données
-- personnelles professionnelles ; le contrat ne fournit pas de valeur de tag adaptée.
SELECT level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
  'NYC_TAXI.RAW.DRIVER_SHIFTS', 'table'));

