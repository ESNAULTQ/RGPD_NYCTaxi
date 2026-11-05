-- depot_connu : le dépôt est exactement Bronx, Brooklyn ou Queens.
-- Les deux tables RAW portent cette information ; leurs anomalies sont additionnées.
-- Une ligne et une colonne ; seuil contractuel = 0, non bloquant.
SELECT
    (SELECT COUNT_IF(depot NOT IN ('Bronx', 'Brooklyn', 'Queens') OR depot IS NULL)
     FROM NYC_TAXI.RAW.DRIVERS)
  + (SELECT COUNT_IF(depot NOT IN ('Bronx', 'Brooklyn', 'Queens') OR depot IS NULL)
     FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS nb_anomalies;
