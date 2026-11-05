-- =====================================================================
-- taches_rh_test_blocage.sql — preuve temporaire du blocage du graphe
-- Exécuter EN ENTIER avec TRANSFORMER après une exécution normale réussie.
-- Ce test remplace temporairement le corps de T_QUALITE : seuil 0 au lieu de 50.
-- APRÈS LA PREUVE, réexécuter taches_rh.sql pour restaurer la vraie tâche.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Une racine suspendue est obligatoire avant de modifier une tâche du graphe.
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_PURGE SUSPEND;
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_QUALITE SUSPEND;
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_TABLES SUSPEND;

-- Variante de test minimale : elle mesure et historise service_rattache,
-- puis échoue volontairement puisque le jeu contient 25 anomalies > 0.
ALTER TASK NYC_TAXI.MARTS.T_QUALITE MODIFY AS
EXECUTE IMMEDIATE $$
DECLARE
  mesure_le       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
  nb_service      NUMBER DEFAULT 0;
  service_bloque  EXCEPTION (-20001, 'TEST : service_rattache dépasse le seuil temporaire de 0');
BEGIN
  SELECT COUNT(*) INTO :nb_service
  FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
  WHERE NOT EXISTS (
    SELECT 1 FROM NYC_TAXI.RAW.DRIVERS d WHERE d.driver_id = s.driver_id
  );

  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  SELECT 'service_rattache', :mesure_le, :nb_service, 0,
         IFF(:nb_service > 0, 'ALERTE', 'OK');

  IF (nb_service > 0) THEN
    RAISE service_bloque;
  END IF;

  RETURN 'Test non bloqué : aucune anomalie';
END;
$$;

-- Activer tout le graphe puis lancer la racine immédiatement.
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('NYC_TAXI.MARTS.T_PURGE');
EXECUTE TASK NYC_TAXI.MARTS.T_PURGE;

-- Attendre environ une minute avant d'interroger TASK_HISTORY.
