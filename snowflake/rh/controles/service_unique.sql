-- service_unique : un identifiant de service n'apparaît qu'une fois.
-- Une ligne et une colonne ; seuil contractuel = 0, non bloquant.
SELECT COUNT(*) - COUNT(DISTINCT shift_id) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVER_SHIFTS;
