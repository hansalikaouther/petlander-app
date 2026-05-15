-- =============================================================
-- Petlander — Fonction de suppression du compte utilisateur
-- =============================================================
-- À exécuter dans le SQL Editor de Supabase APRÈS les triggers.
-- Permet à l'utilisateur connecté de supprimer son propre compte
-- (ses données + son entrée auth.users).
--
-- Sécurité : SECURITY DEFINER + check auth.uid() = user_id pour
-- empêcher un utilisateur de supprimer un autre compte.
-- =============================================================

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  uid UUID;
BEGIN
  uid := auth.uid();
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1) Supprimer toutes les données métier de l'utilisateur
  --    (les ON DELETE CASCADE des FK font le reste)
  DELETE FROM public.utilisateur WHERE id_utilisateur = uid;

  -- 2) Supprimer le compte auth (cascade vers tout ce qui dépend de auth.users)
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

-- Permet à tout utilisateur authentifié d'appeler cette fonction
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
