-- =============================================================
-- Petlander — Row Level Security (RLS)
-- =============================================================
-- Chaque utilisateur ne voit/modifie QUE ses propres données.
-- Les tables référentielles (vaccin, allergie, maladie_chronique)
-- restent en lecture publique pour tous les utilisateurs authentifiés.
-- =============================================================

-- ===== ACTIVATION du RLS sur toutes les tables utilisateur =====
ALTER TABLE public.utilisateur            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.animal                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.veterinaire            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vaccination            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultation           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.traitement             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examen                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operation_chirurgicale ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historique_croissance  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avoir_allergie         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avoir_maladie_chronique ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rdv                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rappel                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_medical       ENABLE ROW LEVEL SECURITY;

-- Référentiels en lecture seule pour tout authentifié
ALTER TABLE public.vaccin             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.allergie           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maladie_chronique  ENABLE ROW LEVEL SECURITY;

-- =============================================================
-- UTILISATEUR
-- =============================================================
CREATE POLICY "user_select_own" ON public.utilisateur
  FOR SELECT USING (auth.uid() = id_utilisateur);

CREATE POLICY "user_insert_self" ON public.utilisateur
  FOR INSERT WITH CHECK (auth.uid() = id_utilisateur);

CREATE POLICY "user_update_own" ON public.utilisateur
  FOR UPDATE USING (auth.uid() = id_utilisateur);

CREATE POLICY "user_delete_own" ON public.utilisateur
  FOR DELETE USING (auth.uid() = id_utilisateur);

-- =============================================================
-- ANIMAL — propriétaire = id_utilisateur
-- =============================================================
CREATE POLICY "animal_all_own" ON public.animal
  FOR ALL USING (auth.uid() = id_utilisateur)
           WITH CHECK (auth.uid() = id_utilisateur);

-- =============================================================
-- VETERINAIRE — chaque user gère sa liste de vétos
-- =============================================================
CREATE POLICY "vet_all_own" ON public.veterinaire
  FOR ALL USING (auth.uid() = id_utilisateur)
           WITH CHECK (auth.uid() = id_utilisateur);

-- =============================================================
-- Helper inline : vérifier que l'animal appartient à l'utilisateur
-- =============================================================
-- (Utilisé dans les politiques des tables liées à un animal)

-- VACCINATION
CREATE POLICY "vacc_all_own_animal" ON public.vaccination
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = vaccination.id_animal
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = vaccination.id_animal
              AND a.id_utilisateur = auth.uid())
  );

-- CONSULTATION
CREATE POLICY "consult_all_own_animal" ON public.consultation
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = consultation.id_animal
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = consultation.id_animal
              AND a.id_utilisateur = auth.uid())
  );

-- TRAITEMENT
CREATE POLICY "trait_all_own_animal" ON public.traitement
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = traitement.id_animal
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = traitement.id_animal
              AND a.id_utilisateur = auth.uid())
  );

-- EXAMEN (via consultation -> animal)
CREATE POLICY "examen_all_own_animal" ON public.examen
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.consultation c
            JOIN public.animal a ON a.id_animal = c.id_animal
            WHERE c.id_consultation = examen.id_consultation
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.consultation c
            JOIN public.animal a ON a.id_animal = c.id_animal
            WHERE c.id_consultation = examen.id_consultation
              AND a.id_utilisateur = auth.uid())
  );

-- OPERATION_CHIRURGICALE
CREATE POLICY "op_all_own_animal" ON public.operation_chirurgicale
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = operation_chirurgicale.id_animal
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = operation_chirurgicale.id_animal
              AND a.id_utilisateur = auth.uid())
  );

-- HISTORIQUE_CROISSANCE
CREATE POLICY "growth_all_own_animal" ON public.historique_croissance
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = historique_croissance.id_animal
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = historique_croissance.id_animal
              AND a.id_utilisateur = auth.uid())
  );

-- AVOIR_ALLERGIE
CREATE POLICY "allergie_all_own_animal" ON public.avoir_allergie
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = avoir_allergie.id_animal
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = avoir_allergie.id_animal
              AND a.id_utilisateur = auth.uid())
  );

-- AVOIR_MALADIE_CHRONIQUE
CREATE POLICY "maladie_all_own_animal" ON public.avoir_maladie_chronique
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = avoir_maladie_chronique.id_animal
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = avoir_maladie_chronique.id_animal
              AND a.id_utilisateur = auth.uid())
  );

-- RDV — propriétaire direct via id_utilisateur
CREATE POLICY "rdv_all_own" ON public.rdv
  FOR ALL USING (auth.uid() = id_utilisateur)
           WITH CHECK (auth.uid() = id_utilisateur);

-- RAPPEL
CREATE POLICY "rappel_all_own" ON public.rappel
  FOR ALL USING (auth.uid() = id_utilisateur)
           WITH CHECK (auth.uid() = id_utilisateur);

-- NOTIFICATION
CREATE POLICY "notif_all_own" ON public.notification
  FOR ALL USING (auth.uid() = id_utilisateur)
           WITH CHECK (auth.uid() = id_utilisateur);

-- DOCUMENT_MEDICAL
CREATE POLICY "doc_all_own_animal" ON public.document_medical
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = document_medical.id_animal
              AND a.id_utilisateur = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.animal a
            WHERE a.id_animal = document_medical.id_animal
              AND a.id_utilisateur = auth.uid())
  );

-- =============================================================
-- RÉFÉRENTIELS — lecture publique pour tout authentifié
-- =============================================================
CREATE POLICY "vaccin_read_authenticated" ON public.vaccin
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "allergie_read_authenticated" ON public.allergie
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "maladie_read_authenticated" ON public.maladie_chronique
  FOR SELECT USING (auth.role() = 'authenticated');
