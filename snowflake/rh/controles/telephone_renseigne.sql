-- telephone_renseigne : chaque chauffeur en poste a un téléphone.
-- Une ligne et une colonne ; seuil dynamique = 5 % des chauffeurs en poste.
SELECT COUNT_IF(phone IS NULL OR TRIM(phone) = '') AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS
WHERE end_date IS NULL;

-- Le seuil numérique historisé par T_QUALITE est calculé ainsi :
-- SELECT COUNT_IF(end_date IS NULL) * 0.05 FROM NYC_TAXI.RAW.DRIVERS;
