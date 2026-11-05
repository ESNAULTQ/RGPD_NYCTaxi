-- licence_unique : un numéro de licence TLC n'appartient qu'à un seul chauffeur.
-- Une ligne et une colonne ; seuil contractuel = 0, non bloquant.
SELECT COUNT(*) - COUNT(DISTINCT tlc_license_number) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS;
