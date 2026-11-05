-- email_valide : l'e-mail contient un @.
-- Une ligne et une colonne ; seuil contractuel = 0, non bloquant.
SELECT COUNT_IF(email IS NULL OR NOT CONTAINS(email, '@')) AS nb_anomalies
FROM NYC_TAXI.RAW.DRIVERS;
