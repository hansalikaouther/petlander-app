-- =============================================================
-- Petlander — Fix RLS : tables référentielles allergie & maladie
-- =============================================================
-- Problème : les tables allergie et maladie_chronique n'avaient
-- que des policies SELECT pour les users authentifiés.
-- Résultat : les entrées personnalisées (non présentes dans le
-- catalogue) ne pouvaient pas être créées → échec silencieux.
--
-- À exécuter dans le SQL Editor de Supabase après 02_rls_policies.sql
-- =============================================================

-- ===== ALLERGIE — ajout INSERT pour users authentifiés =====
CREATE POLICY IF NOT EXISTS "allergie_insert_authenticated"
  ON public.allergie
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- ===== MALADIE_CHRONIQUE — ajout INSERT pour users authentifiés =====
CREATE POLICY IF NOT EXISTS "maladie_insert_authenticated"
  ON public.maladie_chronique
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');
