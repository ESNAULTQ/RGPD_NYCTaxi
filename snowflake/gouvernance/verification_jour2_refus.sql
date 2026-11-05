-- =====================================================================
-- verification_jour2_refus.sql — preuves négatives, UN BLOC À LA FOIS
-- Ces requêtes DOIVENT échouer. Ne pas exécuter le fichier en entier.
-- Ne jamais accorder de privilège supplémentaire pour supprimer l'erreur.
-- =====================================================================

-- A07 — GOUVERNANCE : attendu = object does not exist or not authorized.
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;

-- A09 — PUBLIC : attendu = warehouse ou object access denied.
-- Sélectionner ce bloc séparément après avoir capturé A07.
USE SECONDARY ROLES NONE;
USE ROLE PUBLIC;
USE WAREHOUSE NYC_TAXI_WH;
SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER;

