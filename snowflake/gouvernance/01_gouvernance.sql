-- =====================================================================
-- 01_gouvernance.sql — fondation de gouvernance du jour 1
-- Crée le rôle et le schéma GOUVERNANCE, les trois tags contractuels et
-- QUALITE_RESULTATS. Aucun SELECT RH n'est accordé à GOUVERNANCE.
-- Exécuter en entier après 00_installation.sql. Rejouable.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
SET utilisateur_courant = CURRENT_USER();

-- Le rôle qui écrit les règles sans lire les valeurs RH.
CREATE ROLE IF NOT EXISTS GOUVERNANCE
  COMMENT = 'Administre tags et politiques du domaine RH sans lire les données RH';
GRANT ROLE GOUVERNANCE TO USER IDENTIFIER($utilisateur_courant);

-- Visibilité des objets et capacité à attacher les politiques du jour 2.
GRANT USAGE ON WAREHOUSE NYC_TAXI_WH TO ROLE GOUVERNANCE;
GRANT USAGE ON DATABASE NYC_TAXI TO ROLE GOUVERNANCE;
GRANT USAGE ON SCHEMA NYC_TAXI.RAW TO ROLE GOUVERNANCE;
GRANT USAGE ON SCHEMA NYC_TAXI.MARTS TO ROLE GOUVERNANCE;
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE GOUVERNANCE;
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE GOUVERNANCE;

-- ACCOUNTADMIN crée puis remet le schéma au rôle spécialisé.
CREATE SCHEMA IF NOT EXISTS NYC_TAXI.GOUVERNANCE
  COMMENT = 'Tags, politiques, correspondances, catalogue et résultats de qualité du domaine RH';
GRANT OWNERSHIP ON SCHEMA NYC_TAXI.GOUVERNANCE
  TO ROLE GOUVERNANCE COPY CURRENT GRANTS;

USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;

CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.SENSIBILITE
  ALLOWED_VALUES 'public', 'interne', 'confidentiel'
  COMMENT = 'Niveau de sensibilité d''une table cataloguée';

CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE
  ALLOWED_VALUES 'nom', 'email', 'telephone', 'date_naissance',
                 'identifiant_officiel', 'identifiant_interne'
  COMMENT = 'Nature contractuelle d''une colonne personnelle ou dérivée';

CREATE TAG IF NOT EXISTS NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION
  COMMENT = 'Durée ou critère de conservation applicable à une table cataloguée';

CREATE TABLE IF NOT EXISTS NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS (
    regle         VARCHAR       NOT NULL,
    mesure_le     TIMESTAMP_NTZ NOT NULL,
    nb_anomalies  NUMBER        NOT NULL,
    seuil         NUMBER(18, 2) NOT NULL,
    statut        VARCHAR       NOT NULL
)
COMMENT = 'Historique append-only des mesures de qualité : statut attendu OK ou ALERTE';

-- TRANSFORMER pose les tags sur les objets qu'il possède, écrit les mesures
-- de qualité et créera V_CATALOGUE, sans posséder le schéma de gouvernance.
GRANT USAGE ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.SENSIBILITE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.DONNEE_PERSONNELLE TO ROLE TRANSFORMER;
GRANT APPLY ON TAG NYC_TAXI.GOUVERNANCE.DUREE_CONSERVATION TO ROLE TRANSFORMER;
GRANT INSERT, SELECT ON TABLE NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS TO ROLE TRANSFORMER;
GRANT CREATE VIEW ON SCHEMA NYC_TAXI.GOUVERNANCE TO ROLE TRANSFORMER;

-- Vérifications. Inspecter les résultats réels avant de valider le jour 1.
SHOW TAGS IN SCHEMA NYC_TAXI.GOUVERNANCE;
SHOW GRANTS TO ROLE GOUVERNANCE;
SHOW GRANTS TO ROLE TRANSFORMER;
DESC TABLE NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS;

