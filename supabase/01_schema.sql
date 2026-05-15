-- =============================================================
-- Petlander — Schéma de base de données (PostgreSQL / Supabase)
-- =============================================================
-- À exécuter dans le SQL Editor de Supabase.
-- L'ordre est important : les tables référencées doivent exister
-- avant les tables qui les référencent.
-- =============================================================

-- ===== EXTENSION pour gen_random_uuid() =====
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================
-- 1. UTILISATEUR
-- =============================================================
-- Lié à auth.users (Supabase Auth) via id_utilisateur = auth.uid()
CREATE TABLE IF NOT EXISTS public.utilisateur (
  id_utilisateur UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nom            VARCHAR(100) NOT NULL,
  adresse        TEXT,
  numero_telephone VARCHAR(20),
  email          VARCHAR(150) UNIQUE NOT NULL,
  avatar_url     TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 2. ANIMAL
-- =============================================================
CREATE TABLE IF NOT EXISTS public.animal (
  id_animal      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur UUID NOT NULL REFERENCES public.utilisateur(id_utilisateur) ON DELETE CASCADE,
  nom            VARCHAR(100) NOT NULL,
  type           VARCHAR(50)  NOT NULL,    -- chien, chat, lapin, etc.
  race           VARCHAR(100),
  date_naissance DATE,
  sexe           VARCHAR(10),
  couleur        VARCHAR(50),
  poids_actuel   NUMERIC(5,2),
  photo_url      TEXT,
  numero_puce    VARCHAR(50),
  sterilise      BOOLEAN DEFAULT FALSE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 3. VETERINAIRE
-- =============================================================
CREATE TABLE IF NOT EXISTS public.veterinaire (
  id_veterinaire UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur UUID REFERENCES public.utilisateur(id_utilisateur) ON DELETE CASCADE,
  nom            VARCHAR(100) NOT NULL,
  adresse        TEXT,
  numero_telephone VARCHAR(20),
  email          VARCHAR(150),
  specialite     VARCHAR(100),
  photo_url      TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 4. VACCIN (référentiel global)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.vaccin (
  id_vaccin            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom_vaccin           VARCHAR(150) NOT NULL,
  type_animal          VARCHAR(50),         -- chien, chat, tous
  description          TEXT,
  duree_validite_mois  INTEGER
);

-- =============================================================
-- 5. VACCINATION (instance pour un animal)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.vaccination (
  id_vaccination UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_animal      UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  id_vaccin      UUID REFERENCES public.vaccin(id_vaccin),
  nom_vaccin     VARCHAR(150),
  date_vaccination DATE NOT NULL,
  date_rappel    DATE,
  id_veterinaire UUID REFERENCES public.veterinaire(id_veterinaire),
  lot_vaccin     VARCHAR(50),
  notes          TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 6. CONSULTATION
-- =============================================================
CREATE TABLE IF NOT EXISTS public.consultation (
  id_consultation UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_animal       UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  id_veterinaire  UUID REFERENCES public.veterinaire(id_veterinaire),
  date_consultation TIMESTAMPTZ NOT NULL,
  motif           VARCHAR(200),
  diagnostic      TEXT,
  observation     TEXT,
  poids           NUMERIC(5,2),
  taille          NUMERIC(5,2),
  temperature     NUMERIC(4,1),
  notification    BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 7. TRAITEMENT
-- =============================================================
CREATE TABLE IF NOT EXISTS public.traitement (
  id_traitement   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_consultation UUID REFERENCES public.consultation(id_consultation) ON DELETE CASCADE,
  id_animal       UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  nom_medicament  VARCHAR(200),
  photo_ordo_url  TEXT,
  duree_traitement VARCHAR(100),
  posologie       TEXT,
  date_debut      DATE,
  date_fin        DATE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 8. EXAMEN
-- =============================================================
CREATE TABLE IF NOT EXISTS public.examen (
  id_examen       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_consultation UUID NOT NULL REFERENCES public.consultation(id_consultation) ON DELETE CASCADE,
  type_examen     VARCHAR(150) NOT NULL,
  date            DATE NOT NULL,
  compte_rendu    TEXT,
  document_url    TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 9. OPERATION CHIRURGICALE
-- =============================================================
CREATE TABLE IF NOT EXISTS public.operation_chirurgicale (
  id_operation   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_animal      UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  id_veterinaire UUID REFERENCES public.veterinaire(id_veterinaire),
  type_operation VARCHAR(200) NOT NULL,
  date_operation DATE NOT NULL,
  duree          VARCHAR(50),
  notification   BOOLEAN DEFAULT FALSE,
  compte_rendu   TEXT,
  documents_url  TEXT[],
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 10. HISTORIQUE_CROISSANCE
-- =============================================================
CREATE TABLE IF NOT EXISTS public.historique_croissance (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_animal       UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  date            DATE NOT NULL,
  poids           NUMERIC(5,2),
  taille          NUMERIC(5,2),
  indice_corporel NUMERIC(4,2),
  obs             TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 11. ALLERGIE (référentiel) + AVOIR_ALLERGIE
-- =============================================================
CREATE TABLE IF NOT EXISTS public.allergie (
  id_allergie UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom         VARCHAR(150) NOT NULL,
  obs         TEXT
);

CREATE TABLE IF NOT EXISTS public.avoir_allergie (
  id_allergie    UUID NOT NULL REFERENCES public.allergie(id_allergie) ON DELETE CASCADE,
  id_animal      UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  date_detection DATE,
  notes          TEXT,
  PRIMARY KEY (id_allergie, id_animal)
);

-- =============================================================
-- 12. MALADIE_CHRONIQUE (référentiel) + AVOIR_MALADIE_CHRONIQUE
-- =============================================================
CREATE TABLE IF NOT EXISTS public.maladie_chronique (
  id_maladie   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom_maladie  VARCHAR(150) NOT NULL,
  description  TEXT
);

CREATE TABLE IF NOT EXISTS public.avoir_maladie_chronique (
  id_maladie      UUID NOT NULL REFERENCES public.maladie_chronique(id_maladie) ON DELETE CASCADE,
  id_animal       UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  date_diagnostic DATE,
  notes           TEXT,
  PRIMARY KEY (id_maladie, id_animal)
);

-- =============================================================
-- 13. RDV
-- =============================================================
CREATE TABLE IF NOT EXISTS public.rdv (
  id_rdv          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_animal       UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  id_utilisateur  UUID REFERENCES public.utilisateur(id_utilisateur) ON DELETE CASCADE,
  id_veterinaire  UUID REFERENCES public.veterinaire(id_veterinaire),
  id_consultation UUID REFERENCES public.consultation(id_consultation),
  date_heure      TIMESTAMPTZ NOT NULL,
  motif           VARCHAR(200),
  statut          VARCHAR(30) DEFAULT 'planifie',  -- planifie, confirme, annule, passe
  notification    BOOLEAN DEFAULT TRUE,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 14. RAPPEL
-- =============================================================
CREATE TABLE IF NOT EXISTS public.rappel (
  id_rappel      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur UUID REFERENCES public.utilisateur(id_utilisateur) ON DELETE CASCADE,
  id_rdv         UUID REFERENCES public.rdv(id_rdv) ON DELETE CASCADE,
  date           DATE NOT NULL,
  message        TEXT NOT NULL,
  type_rappel    VARCHAR(50),  -- vaccin, rdv, traitement, general
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 15. NOTIFICATION
-- =============================================================
CREATE TABLE IF NOT EXISTS public.notification (
  id_notification UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur  UUID REFERENCES public.utilisateur(id_utilisateur) ON DELETE CASCADE,
  id_rappel       UUID REFERENCES public.rappel(id_rappel) ON DELETE SET NULL,
  titre           VARCHAR(200) NOT NULL,
  contenu         TEXT,
  date_envoi      TIMESTAMPTZ DEFAULT NOW(),
  lue             BOOLEAN DEFAULT FALSE,
  type            VARCHAR(50)
);

-- =============================================================
-- 16. DOCUMENT_MEDICAL
-- =============================================================
CREATE TABLE IF NOT EXISTS public.document_medical (
  id_document   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_animal     UUID NOT NULL REFERENCES public.animal(id_animal) ON DELETE CASCADE,
  titre         VARCHAR(200) NOT NULL,
  type_document VARCHAR(100), -- ordonnance, resultat_examen, certificat, autre
  fichier_url   TEXT NOT NULL,
  date_document DATE,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- INDEX pour optimiser les requêtes les plus fréquentes
-- =============================================================
CREATE INDEX IF NOT EXISTS idx_animal_user           ON public.animal(id_utilisateur);
CREATE INDEX IF NOT EXISTS idx_vaccination_animal    ON public.vaccination(id_animal);
CREATE INDEX IF NOT EXISTS idx_vaccination_rappel    ON public.vaccination(date_rappel);
CREATE INDEX IF NOT EXISTS idx_consultation_animal   ON public.consultation(id_animal);
CREATE INDEX IF NOT EXISTS idx_consultation_date     ON public.consultation(date_consultation);
CREATE INDEX IF NOT EXISTS idx_traitement_animal     ON public.traitement(id_animal);
CREATE INDEX IF NOT EXISTS idx_operation_animal      ON public.operation_chirurgicale(id_animal);
CREATE INDEX IF NOT EXISTS idx_croissance_animal     ON public.historique_croissance(id_animal);
CREATE INDEX IF NOT EXISTS idx_rdv_animal            ON public.rdv(id_animal);
CREATE INDEX IF NOT EXISTS idx_rdv_user_date         ON public.rdv(id_utilisateur, date_heure);
CREATE INDEX IF NOT EXISTS idx_rappel_user_date      ON public.rappel(id_utilisateur, date);
CREATE INDEX IF NOT EXISTS idx_notif_user_lue        ON public.notification(id_utilisateur, lue);
CREATE INDEX IF NOT EXISTS idx_doc_animal            ON public.document_medical(id_animal);
