# VoteBanker frontend

Flutter app (web first; Android/iOS folders included). Six languages: English, Hindi, Kannada, Malayalam, Tamil, Telugu.

| | |
|---|---|
| Live site | https://votebanker-frontend.vercel.app |
| Backend API | https://votebankerbackend-production.up.railway.app (repo: `VoteBanker_Backend`) |

## Run locally

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).
2. From this folder:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```
   By default the app talks to the live Railway backend. To use a backend running on your machine:
   ```bash
   flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
   ```

No `.env` is needed for the frontend. The only setting is `API_BASE_URL` (see `lib/core/config/app_config.dart`). **Never put secret keys in this app**, because everything in a web build is public.

## Where things are

- `lib/features/onboarding/` screens: login, mobile OTP, profile, domain, website, social, VRM, ready
- `lib/core/services/auth_service.dart` OTP send/verify and session storage
- `lib/core/services/profile_service.dart` saves onboarding answers to the backend (called from `AppRouter.open`)
- `lib/app/localization/translations/` language files
- `vercel.json`, `build.sh` Vercel build (installs Flutter, builds web)

## Deploy

Deploys are automatic: the Vercel project `votebanker-frontend` (team `votebanker`) is linked to this GitHub repo, so every push to `main` goes live in a few minutes. Pushes to other branches get a preview link only. If a deploy fails, check the Deployments tab in Vercel.

The production backend must list the site in its `CORS_ORIGINS` variable.

Theme: colors come from `context.palette.*` (light and dark), not `AppColors.*`. Use the palette in new screens so they look right in both modes.

## To do

- New login/OTP screen text is English only; add translations to all six language files.
- Email sign-in, WhatsApp OTP, and profile photo upload are not built yet (see the backend README).
- "Skip for now" on the login screen opens onboarding without signing in; decide if that should stay.

## Rules

- Branch from `main`, open a pull request, and pull the latest `main` before you push.
- Run `flutter analyze` before pushing.
