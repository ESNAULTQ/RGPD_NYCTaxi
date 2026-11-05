-- duree_plausible : un service ne dure pas plus de 16 heures.
-- Une ligne et une colonne ; seuil contractuel = 0, non bloquant.
SELECT COUNT_IF(hours_worked > 16) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVER_SHIFTS;
