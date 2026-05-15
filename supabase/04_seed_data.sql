-- =============================================================
-- Petlander — Données de seed (référentiels)
-- =============================================================
-- Vaccins courants pour chiens et chats, principales allergies
-- et maladies chroniques. À exécuter une fois après le schéma.
-- =============================================================

-- ===== VACCINS chiens =====
INSERT INTO public.vaccin (nom_vaccin, type_animal, description, duree_validite_mois) VALUES
  ('CHPPi (Carré, Hépatite, Parvo, Para-influenza)', 'chien', 'Vaccin polyvalent canin de base', 12),
  ('Leptospirose', 'chien', 'Protection contre la leptospirose', 12),
  ('Rage',         'chien', 'Vaccination obligatoire contre la rage', 12),
  ('Toux du chenil (Bordetella)', 'chien', 'Recommandé pour chiens en collectivité', 12),
  ('Piroplasmose', 'chien', 'Protection contre la piroplasmose (tiques)', 6)
ON CONFLICT DO NOTHING;

-- ===== VACCINS chats =====
INSERT INTO public.vaccin (nom_vaccin, type_animal, description, duree_validite_mois) VALUES
  ('Typhus (Panleucopénie)', 'chat', 'Vaccin de base félin', 12),
  ('Coryza (Calicivirus + Herpèsvirus)', 'chat', 'Vaccin de base félin', 12),
  ('Leucose féline (FeLV)', 'chat', 'Recommandé pour chats sortants', 12),
  ('Rage',                  'chat', 'Obligatoire en cas de voyage', 12),
  ('Chlamydiose',           'chat', 'Optionnel selon contexte', 12)
ON CONFLICT DO NOTHING;

-- ===== ALLERGIES courantes =====
INSERT INTO public.allergie (nom, obs) VALUES
  ('Allergie alimentaire (poulet)', 'Réaction cutanée fréquente'),
  ('Allergie alimentaire (bœuf)', NULL),
  ('Allergie aux puces (DAPP)', 'Dermatite par allergie aux piqûres de puces'),
  ('Allergie au pollen', NULL),
  ('Allergie aux acariens', NULL),
  ('Allergie médicamenteuse', 'Préciser la molécule en notes')
ON CONFLICT DO NOTHING;

-- ===== MALADIES CHRONIQUES =====
INSERT INTO public.maladie_chronique (nom_maladie, description) VALUES
  ('Diabète', 'Diabète sucré nécessitant un suivi glycémique'),
  ('Insuffisance rénale chronique', 'Suivi régulier des paramètres rénaux'),
  ('Arthrose', 'Maladie articulaire dégénérative'),
  ('Épilepsie', 'Crises convulsives récurrentes'),
  ('Hypothyroïdie', 'Insuffisance thyroïdienne'),
  ('Cardiopathie', 'Pathologie cardiaque (préciser le type)')
ON CONFLICT DO NOTHING;
