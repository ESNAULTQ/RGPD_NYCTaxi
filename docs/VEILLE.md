# Note de veille réglementaire — données du personnel de Hudson Cab Partners

> **Version préparée le 2 novembre 2026, mise à jour le 5 novembre 2026.** Les conclusions ci-dessous sont une analyse de travail, pas un avis juridique. Les faits marqués **À CONFIRMER** doivent être validés par le DPO ou le conseil juridique. Les abonnements réellement disponibles sont distingués du suivi manuel afin de ne pas inventer une alerte.

## 1. Le droit applicable

Le traitement étudié concerne des chauffeurs employés à New York. Le contexte du brief indique que Hudson Cab Europe, établie à Paris, assure désormais la gestion et détermine l'usage des données du personnel.

| Question | Réponse de travail | Source officielle |
|---|---|---|
| Le RGPD s'applique-t-il ? | **Probablement oui au titre de l'article 3(1)**, si le traitement est effectué dans le cadre des activités de l'établissement parisien qui en détermine l'usage. Cette condition factuelle doit être confirmée. | [RGPD, art. 3(1), EUR-Lex](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679) ; [CEPD, lignes directrices 3/2018](https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-32018-territorial-scope-gdpr-article-3-version_fr) |
| Pourquoi alors que les chauffeurs sont à New York ? | L'article 3(1) rattache le traitement aux activités d'un établissement dans l'Union, indépendamment du lieu du traitement. Les lignes directrices du CEPD précisent que ce critère ne dépend pas de la nationalité ou du lieu de résidence des personnes. L'article 3(2) n'est donc pas le fondement nécessaire dans cette hypothèse. | RGPD, art. 3(1) et considérant 14 ; CEPD 3/2018, critère de l'établissement |
| Qui est responsable du traitement ? | **Hudson Cab Europe est vraisemblablement responsable** si elle détermine réellement les finalités et les moyens. Le rôle de Hudson Cab Partners US reste **À CONFIRMER** : responsable conjoint, responsable distinct ou sous-traitant selon ses décisions et instructions réelles. Snowflake est présumé sous-traitant pour l'hébergement sur instruction, sous réserve du contrat et des usages propres. | RGPD, art. 4(7), 4(8), 26 et 28 ; [CNIL, identifier son rôle, 6 juin 2025](https://www.cnil.fr/fr/rgpd-comment-bien-identifier-son-role) |
| Quelle autorité est compétente ? | La CNIL est compétente pour l'établissement français. Son statut éventuel d'autorité chef de file dépend du lieu de l'établissement principal et du lieu où sont prises les décisions sur le traitement : **À CONFIRMER**. | RGPD, art. 55 et 56 |
| Y a-t-il un transfert hors EEE ? | La région observée est `AWS_EU_WEST_3`, soit AWS `eu-west-3`, EU (Paris). L'hébergement principal est donc situé en France. Les lieux de réplication, de support et les sous-traitants restent **À CONFIRMER** : une région EEE ne suffit pas si un accès ou une copie vers un pays tiers existe. | RGPD, art. 44 à 49 ; [Snowflake, régions prises en charge](https://docs.snowflake.com/en/user-guide/intro-regions) ; [CNIL, identifier les transferts hors UE](https://www.cnil.fr/fr/responsables-de-traitement-comment-identifier-et-traiter-des-transferts-de-donnees-hors-ue) |

### Faits à obtenir avant une conclusion juridique définitive

- identité contractuelle des entités américaine et européenne ;
- entité qui décide des finalités RH, des destinataires et de la durée ;
- base légale retenue pour chaque finalité RH ;
- réplication, support et liste des sous-traitants ultérieurs Snowflake (région principale observée : AWS Paris) ;
- DPA conclu avec Snowflake et mécanisme de transfert applicable ;
- droit du travail new-yorkais applicable aux durées de conservation.

## 2. Dispositif de veille configuré

| Source | Type | Surveillance | Fréquence | Outil et état |
|---|---|---|---|---|
| [Actualités et RSS de la CNIL](https://www.cnil.fr/fr/rss.xml) | Autorité française | RH, sécurité, durées, sous-traitance, transferts | Hebdomadaire | Inoreader — actif depuis le 5 novembre 2026 ; preuve : [`01a_veille_sources.png`](01a_veille_sources.png) |
| [Actualités du CEPD](https://www.edpb.europa.eu/news/news_fr) | Autorité européenne | Lignes directrices et décisions européennes | Hebdomadaire | Inoreader — actif depuis le 5 novembre 2026 ; preuve : [`01a_veille_sources.png`](01a_veille_sources.png) |
| [EUR-Lex — règlement 2016/679](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679) | Journal officiel de l'UE | Texte consolidé, rectificatifs et actes liés | Mensuelle | Revue manuelle mensuelle : la création du compte My EUR-Lex n'a pas abouti le 5 novembre 2026, donc aucune alerte automatique n'est revendiquée |

Responsable de lecture : **responsable du projet**. Suppléant : **responsable du projet (même personne)**. L'absence de suppléant indépendant est une limite organisationnelle connue. Toute nouveauté ayant un impact est inscrite dans le journal de décisions du README avec propriétaire et échéance.

## 3. Fiches de veille

### Fiche 1 — Champ territorial du RGPD

- **Source** : CEPD, [Lignes directrices 3/2018 relatives au champ d'application territorial](https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-32018-territorial-scope-gdpr-article-3-version_fr)
- **Date** : version finale adoptée le 12 novembre 2019, version 2.1 du 7 janvier 2020 · consultée le 2 novembre 2026
- **Enseignement** : le critère de l'établissement de l'article 3(1) peut rendre le RGPD applicable même lorsque les personnes et l'infrastructure se trouvent hors de l'Union. Il faut un lien réel entre l'activité de l'établissement européen et le traitement.
- **Impact Snowflake** : documenter qui décide depuis Paris, la région et les accès internationaux ; ne pas conclure à l'inapplicabilité au seul motif que les chauffeurs résident à New York.
- **Action** : validation DPO/juriste des faits et de la qualification des entités.

### Fiche 2 — Principes de minimisation, exactitude, conservation et sécurité

- **Source** : [RGPD, articles 5, 25 et 32, EUR-Lex](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679)
- **Date** : règlement du 27 avril 2016 · consulté le 2 novembre 2026
- **Enseignement** : les données doivent être nécessaires, exactes, conservées pendant une durée justifiée et protégées par des mesures adaptées au risque. La protection doit être intégrée dès la conception et par défaut.
- **Impact Snowflake** : accès minimal par rôle, masquage, filtre par dépôt, qualité historisée, purge et rétention technique courte. Les colonnes sans besoin métier doivent être supprimées ou justifiées.
- **Action** : mettre en œuvre les contrôles du contrat et conserver les preuves de test.

### Fiche 3 — Durées de conservation des données RH

- **Source** : CNIL, [Référentiel des durées de conservation — gestion des ressources humaines](https://www.cnil.fr/fr/referentiel-durees-conservation-donnees-rh)
- **Date** : publication du 2 avril 2026 ; référentiel mis à jour le 29 janvier 2026 · consulté le 2 novembre 2026
- **Enseignement** : la durée doit être rattachée à une finalité et à un fondement applicable. Le référentiel distingue base active et archivage intermédiaire et avertit que les textes nationaux cités doivent correspondre à la situation réelle.
- **Impact Snowflake** : la règle contractuelle de cinq ans doit être automatisée, mais elle ne suffit pas à prouver sa base juridique pour des chauffeurs new-yorkais. Time Travel et Fail-safe doivent être distingués de l'archivage métier.
- **Action** : appliquer le contrat, signaler l'écart et demander la justification au DPO/juriste selon le droit local.

### Fiche 4 — Sous-traitance, registre et transferts

- **Source** : [RGPD, articles 28, 30 et 44 à 49](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32016R0679) ; [CNIL, identifier et traiter les transferts hors UE](https://www.cnil.fr/fr/responsables-de-traitement-comment-identifier-et-traiter-des-transferts-de-donnees-hors-ue)
- **Date** : consultés le 2 novembre 2026
- **Enseignement** : un sous-traitant agit sur instruction dans un cadre contractuel ; le traitement doit être inscrit au registre ; un transfert hors EEE exige l'identification des lieux et un mécanisme conforme.
- **Impact Snowflake** : vérifier le DPA, la liste des sous-traitants, la région, le support, les réplications et le mécanisme de transfert. Le registre doit refléter les destinataires et mesures réellement appliqués.
- **Action** : obtenir les pièces contractuelles et compléter la partie 2 du registre au jour 3.

## 4. Le contrat face aux textes

| Règle du contrat | Exigence des textes | Source | Appréciation | Écart et recommandation |
|---|---|---|---|---|
| R1 : suppression 5 ans après la fin du contrat | Durée limitée et justifiée par la finalité ou une obligation applicable | RGPD, art. 5(1)(e) ; référentiel CNIL RH 2026 | **Partiellement justifiée** | La règle est techniquement applicable, mais sa base pour des contrats new-yorkais doit être confirmée. Ne pas invoquer automatiquement le code du travail français. |
| R2 : Time Travel limité à 1 jour | Limiter la conservation et protéger les données supprimées | RGPD, art. 5(1)(e), 25 et 32 | **Mesure utile, non suffisante seule** | Documenter le Fail-safe de 7 jours des tables permanentes et qui peut y accéder ; distinguer récupération technique et conservation métier. |
| R3 : fichier retiré du stage | Minimisation, limitation de conservation et sécurité | RGPD, art. 5(1)(c), 5(1)(e), 32 | **Alignée sous réserve de preuve** | Prouver `LIST` vide et contrôler chaque rechargement. |
| Matrice des accès | Accès limité au besoin, protection par défaut et sécurité | RGPD, art. 5(1)(c), 25, 32 | **Alignée dans son principe** | Justifier l'accès intégral de `RH_PAIE`, tester les rôles administratifs et interdire les rôles absents. |
| Règles de qualité | Données exactes et rectifiées sans tarder | RGPD, art. 5(1)(d) | **Alignées dans leur principe** | Les alertes détectent mais ne corrigent pas. Définir un responsable de remédiation et faire valider les seuils métier. |

## 5. Questions non tranchées

À soumettre au DPO ou au conseil juridique :

1. Hudson Cab Europe est-elle responsable unique ou conjointe avec Hudson Cab Partners US ?
2. Quelle base légale couvre paie, gestion des dépôts et analyse d'activité ?
3. Quelle durée le droit new-yorkais impose-t-il pour chaque catégorie RH ?
4. Quelle entité constitue l'établissement principal au sens des articles 55 et 56 ?
5. Quels transferts résultent de la région Snowflake, du support, des réplications et des sous-traitants ?
6. Les chauffeurs ont-ils reçu l'information exigée par les articles 13 ou 14 ?
