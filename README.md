# Petlander - Track, Care And Love

Application mobile multiplateforme (Flutter + Supabase) de carnet de santé numérique pour animaux domestiques. Mémoire de fin d'études.

---

## Stack technique

| Couche | Technologie |
|---|---|
| Frontend | Flutter 3.41+ / Dart 3.11+ |
| Backend & BDD | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| Stockage fichiers | Supabase Storage |
| State management | Riverpod |
| Navigation | GoRouter |
| Notifications | flutter_local_notifications |
| Graphiques | fl_chart |
| Calendrier | table_calendar |

---

## Setup initial

### 1. Configurer Supabase

1. Crée un projet sur [supabase.com](https://supabase.com)
2. Dans **SQL Editor**, exécute dans l'ordre :
   - `supabase/01_schema.sql`
   - `supabase/02_rls_policies.sql`
   - `supabase/03_storage_buckets.sql`
   - `supabase/04_seed_data.sql`
   - `supabase/05_triggers.sql`
3. Récupère **Project URL** et **anon key** depuis Project Settings > API

### 2. Configurer l'environnement Flutter

```bash
cp .env.example .env
# Édite .env avec tes valeurs Supabase
```

### 3. Lancer

```bash
flutter pub get
flutter run
```

---

## Structure du projet

```
lib/
├── main.dart              # Point d'entrée (init Supabase, dotenv, notifications)
├── app.dart               # MaterialApp.router, theme, locale fr_FR
├── core/
│   ├── constants/         # Couleurs, styles, thème
│   ├── services/          # Supabase, notifications, storage, router
│   ├── utils/             # Date utils, validators
│   └── errors/
├── features/              # Une feature par dossier
│   ├── auth/
│   ├── dashboard/
│   ├── animals/
│   ├── vaccinations/
│   ├── consultations/
│   ├── treatments/
│   ├── operations/
│   ├── growth/
│   ├── appointments/
│   ├── notifications/
│   ├── documents/
│   ├── veterinarians/
│   └── profile/
└── shared/
    ├── widgets/           # Composants UI réutilisables
    ├── models/            # Modèles de données
    └── providers/         # Providers Riverpod globaux
```

---

## Design

- **Palette pastel** : bleu `#B5D5F5`, rose `#F5C6D0`, vert menthe `#C8E6C9`
- **Typographie** : Poppins (Google Fonts)
- **Composants** : cards arrondies (radius 20), gradients doux, animations Lottie
- **Bottom nav** + custom AppBar avec avatar animal
- **Mode sombre** prévu via `AppTheme.dark`

---

## État d'avancement

### Phase 1 — Setup terminé
- [x] Projet Flutter initialisé
- [x] Toutes les dépendances installées
- [x] Structure complète `lib/` (core/features/shared)
- [x] Theme + couleurs + typographie
- [x] Services skeleton (Supabase, Notifications, Storage, Router)
- [x] Splash screen + écrans squelettes auth/dashboard
- [x] Scripts SQL Supabase complets (16 tables, RLS, Storage, seed, triggers)

### Phase 2 — Implémentation des écrans (à venir)
- [ ] Login + Inscription complets (Supabase Auth)
- [ ] Dashboard interactif (carousel animaux, prochains rappels)
- [ ] CRUD Animaux + upload photo
- [ ] Vaccinations + timeline + rappels auto
- [ ] Consultations + traitements
- [ ] Opérations chirurgicales
- [ ] Suivi croissance avec graphiques fl_chart
- [ ] Rendez-vous + calendrier
- [ ] Notifications locales programmées
- [ ] Documents médicaux (upload + viewer PDF)
- [ ] Profil utilisateur + paramètres
- [ ] Mode sombre, recherche globale, export PDF

---

## Notes

- Le fichier `.env` est dans `.gitignore` — ne jamais le commit
- Les modèles Dart seront générés au fur et à mesure des features
- Fonctionne sur Android et iOS (Flutter multiplateforme)
