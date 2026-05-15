-- =============================================================
-- Petlander — Triggers et fonctions automatiques
-- =============================================================

-- =============================================================
-- 1. Création automatique de la ligne `utilisateur` à l'inscription
-- =============================================================
-- Lorsqu'un nouveau compte est créé via Supabase Auth (auth.users),
-- on insère automatiquement la ligne correspondante dans `utilisateur`.
-- Le nom et le téléphone peuvent être passés via raw_user_meta_data.
-- =============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.utilisateur (id_utilisateur, nom, email, numero_telephone, adresse)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nom', split_part(NEW.email, '@', 1)),
    NEW.email,
    NEW.raw_user_meta_data->>'numero_telephone',
    NEW.raw_user_meta_data->>'adresse'
  )
  ON CONFLICT (id_utilisateur) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================
-- 2. Calcul automatique de la date_rappel d'une vaccination
-- =============================================================
-- Si l'utilisateur ne fournit pas date_rappel mais qu'un id_vaccin
-- est lié à un vaccin avec duree_validite_mois, on la calcule.
-- =============================================================
CREATE OR REPLACE FUNCTION public.compute_vaccin_rappel()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  validite INTEGER;
BEGIN
  IF NEW.date_rappel IS NULL AND NEW.id_vaccin IS NOT NULL THEN
    SELECT duree_validite_mois INTO validite
    FROM public.vaccin WHERE id_vaccin = NEW.id_vaccin;

    IF validite IS NOT NULL THEN
      NEW.date_rappel := NEW.date_vaccination + make_interval(months => validite);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_compute_vaccin_rappel ON public.vaccination;
CREATE TRIGGER trg_compute_vaccin_rappel
  BEFORE INSERT OR UPDATE ON public.vaccination
  FOR EACH ROW EXECUTE FUNCTION public.compute_vaccin_rappel();

-- =============================================================
-- 3. Mise à jour du poids actuel de l'animal lors d'un nouveau
--    enregistrement de croissance ou consultation
-- =============================================================
CREATE OR REPLACE FUNCTION public.update_animal_weight_from_growth()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.poids IS NOT NULL THEN
    UPDATE public.animal
    SET poids_actuel = NEW.poids
    WHERE id_animal = NEW.id_animal;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_growth_update_weight ON public.historique_croissance;
CREATE TRIGGER trg_growth_update_weight
  AFTER INSERT ON public.historique_croissance
  FOR EACH ROW EXECUTE FUNCTION public.update_animal_weight_from_growth();
