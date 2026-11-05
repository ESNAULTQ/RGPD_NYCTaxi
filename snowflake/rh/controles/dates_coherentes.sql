-- dates_coherentes : pas d'embauche future, pas de fin avant l'embauche.
-- Une ligne et une colonne ; seuil contractuel = 0, non bloquant.
SELECT COUNT_IF(
    hire_date > CURRENT_DATE()
    OR (end_date IS NOT NULL AND end_date < hire_date)
) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS;
