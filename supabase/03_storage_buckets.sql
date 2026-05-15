-- =============================================================
-- Petlander — Buckets de stockage Supabase Storage
-- =============================================================
-- À exécuter dans le SQL Editor APRÈS le schéma et les RLS.
-- Permet l'upload de photos d'animaux, ordonnances, documents.
-- =============================================================

-- ===== Création des buckets =====
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('animals',   'animals',   true),
  ('documents', 'documents', false),
  ('avatars',   'avatars',   true)
ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- POLICIES sur storage.objects
-- =============================================================

-- Les utilisateurs authentifiés peuvent uploader des photos d'animaux
CREATE POLICY "animals_upload_authenticated"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'animals' AND auth.role() = 'authenticated');

CREATE POLICY "animals_select_public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'animals');

CREATE POLICY "animals_delete_own"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'animals' AND auth.uid() = owner);

-- Avatars utilisateurs
CREATE POLICY "avatars_upload_authenticated"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "avatars_select_public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_delete_own"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid() = owner);

-- Documents médicaux : upload et lecture seulement par le propriétaire
CREATE POLICY "documents_upload_authenticated"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'documents' AND auth.role() = 'authenticated');

CREATE POLICY "documents_select_own"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'documents' AND auth.uid() = owner);

CREATE POLICY "documents_delete_own"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'documents' AND auth.uid() = owner);
