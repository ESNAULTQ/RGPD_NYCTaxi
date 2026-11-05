-- service_rattache : chaque service appartient à un chauffeur connu.
-- Une ligne et une colonne ; seuil contractuel = 50, règle BLOQUANTE.
SELECT COUNT(*) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
WHERE NOT EXISTS (
    SELECT 1
    FROM NYC_TAXI.RAW.DRIVERS d
    WHERE d.driver_id = s.driver_id
);
