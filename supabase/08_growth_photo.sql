-- Migration : ajout photo_url dans historique_croissance
-- À exécuter dans Supabase SQL Editor

ALTER TABLE historique_croissance
  ADD COLUMN IF NOT EXISTS photo_url TEXT;
