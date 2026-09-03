# Bailanysta

## Overview

Bailanysta is a small iOS social network for short text posts. Users can read a feed, publish and edit their own posts, like and comment, search by text or hashtag, and optionally turn a rough idea into a polished post with AI.

The project is a production-like slice of a social app: a SwiftUI client talking to a FastAPI backend over HTTP. It is intentionally small. It is not a full Twitter/Instagram clone.

## Features

### Core

- **Feed** — newest posts first, with pull-to-refresh
- **Profile** — current user info, their posts, and appearance (system / light / dark)
- **Create, edit, and delete** own posts (1–1000 characters)
- **Likes** — like and unlike, with optimistic UI on iOS
- **Comments** — list comments and add a new one (1–500 characters)
- **Search** — case-insensitive match on post text; a leading `#` is stripped so `travel` and `#travel` hit the same posts
- **Loading, empty, and error states** — skeletons on first load; `ContentUnavailableView` when empty or failed

### Bonus

- **AI-assisted compose** — “Improve with AI” on the create/edit screen; the generated text is editable before publishing
- **Debug HTTP logging** — request/response traces from `APIClient` in Debug builds only

## Tech Stack

| Technology | Why it is used |
|---|---|
| **SwiftUI** | Native UI for iOS 17+, with system components (`TabView`, `List`, `ContentUnavailableView`) instead of a third-party UI kit |
| **iOS 17+** | `Observation`, SwiftUI data flow, and APIs such as `ContentUnavailableView` without extra compatibility layers |
| **async/await** | One concurrency model from ViewModel → service → `URLSession` |
| **URLSession** | The platform HTTP client; no Alamofire or similar |
| **Python + FastAPI** | Small REST API with automatic OpenAPI docs and Pydantic validation |
| **SQLite** | Zero-ops local database for a coursework-sized app |
| **SQLAlchemy 2** | Typed ORM models and queries without a second data layer |
| **OpenAI Chat Completions (`gpt-4o-mini`)** | One provider call from the backend for post generation; `httpx` is already a project dependency |

## Architecture

### iOS

Feature-based **MVVM**:

```text
View → ViewModel (@Observable) → Service → APIClient → FastAPI
```

- Views render `Loadable` state (loading / loaded / failed). They do not call HTTP.
- ViewModels own screen state and decide like vs unlike from `post.isLiked`.
- Services map operations to endpoints (`PostEndpoint`, `SearchEndpoint`, `UserEndpoint`, `AIEndpoint`).
- `APIClient` builds `URLRequest`, logs in Debug, runs `URLSession`, validates status codes, and decodes snake_case JSON.
- `AppComposition` constructs one `APIClient` and injects it into services. There is no DI framework.

### Backend

```text
Router → service functions → SQLAlchemy → SQLite
```

Routers stay thin. `app/services.py` holds queries and serialization. Pydantic schemas validate writes (non-empty text, length limits). Writes require an `X-User-Id` header that must match a row in `users`.

### Data and AI

```text
iOS  →  FastAPI  →  SQLite
iOS  →  FastAPI  →  OpenAI
```

The iOS app never calls OpenAI. The provider API key lives in backend environment variables. That keeps the key off the device, lets the backend enforce auth and prompt limits, and means provider errors are mapped to HTTP 502/503 instead of leaking raw vendor responses.

Identity is **mock auth**: the app sends `X-User-Id: 1` (seeded user `aikhan`). There is no login, JWT, or password.

## Project Structure

```text
Bailanysta/
├── iOS/Bailanysta/          # Xcode app + unit tests
│   ├── Bailanysta/
│   │   ├── Core/            # networking, models, theme, composition
│   │   └── Features/        # Feed, Post, Profile, Search
│   └── BailanystaTests/     # ViewModel tests with in-memory stubs
└── backend/
    ├── app/                 # FastAPI app, models, routers, AI
    ├── tests/               # pytest against TestClient
    ├── requirements.txt
    └── .env.example
```

| Area | Responsibility |
|---|---|
| `Core/Networking` | `APIClient`, `APIMethod`, endpoints protocol, Debug logger |
| `Features/*/ViewModels` | Screen state and user actions |
| `Features/*/Services` | Typed API calls |
| `backend/app/routers` | HTTP surface |
| `backend/app/models.py` | `User`, `Post`, `Comment`, `Like` |
| `backend/app/ai_service.py` | OpenAI call; key read from the environment |

## Development Process

The app was built in thin vertical slices rather than a big-bang rewrite:

1. iOS shell and `APIClient`
2. FastAPI models and post/user CRUD
3. Connect feed, profile, and compose to the API
4. Likes, comments, search
5. Skeletons and clearer empty/error UI
6. Server-side AI generate
7. Focused tests
8. Networking cleanup (endpoint enums, injected `APIClient`)

Architecture stayed simple on purpose: no repositories, coordinators, or generic “network layer framework.” Each slice reused the same View → ViewModel → Service → `APIClient` path.

## Unique Approaches

- **Server-side AI only** — `POST /ai/generate-post` validates the prompt, calls OpenAI, truncates to 1000 characters, and returns `{ "text": "..." }`. The compose screen puts that text in the editor; publishing is a normal `POST /posts`.
- **Feature folders, not layers-by-type** — Feed, Post, Profile, and Search each own their views, ViewModels, and services.
- **Endpoint enums** — paths and HTTP methods live on `PostEndpoint` (and similar types), not as string literals in services.
- **Like/unlike in the ViewModel** — the service exposes `like` and `unlike`; the ViewModel chooses based on current post state.
- **Skeletons without a UI library** — static SwiftUI placeholders that follow the real row layout; no shimmer package.
- **Search as `ILIKE`** — hashtags are just text in the post body; the API strips a leading `#` so tag and word queries share one code path.
- **Optimistic likes** — the heart updates immediately and reverts if the request fails.

## Trade-offs

These were left out or simplified because the scope is a small, reviewable social client—not a production network at scale.

| Choice | Why it fits this project |
|---|---|
| **No full authentication** | `X-User-Id` is enough to demonstrate ownership (edit/delete) without building signup, tokens, and keychain |
| **No real-time / push** | Feed and comments reload over HTTP; WebSockets would not change the core CRUD story |
| **No recommendations** | Chronological feed is honest and testable |
| **SQLite instead of PostgreSQL** | No server to provision; `DATABASE_URL` can still point at another SQLAlchemy backend later |
| **SQL `ILIKE` instead of Elasticsearch** | Dataset is tiny; search is a teaching feature, not a search product |
| **Simple MVVM** | One pattern everywhere; protocols only where tests need to stub services |
| **Text-only posts** | Images, video, and uploads are a different product |
| **No pagination** | All posts are loaded at once; fine for seeded data, not for a large corpus |

## Known Issues / Limitations

- **Not a production identity system.** Anyone who can reach the API can impersonate a user by sending `X-User-Id`.
- **Simulator-oriented networking.** `APIConfig.baseURL` is `http://127.0.0.1:8000`. That works on the Simulator when the API runs on the same Mac. A physical device needs the Mac’s LAN IP (and still only HTTP).
- **No TLS locally.** Acceptable for local development; not acceptable on a public network.
- **No pagination or feed caching.** Large datasets would load slowly.
- **Comments cannot be edited or deleted.** There are no comment-like endpoints.
- **Profile is the current mock user only.** `GET /users/{id}` exists, but the UI does not browse other profiles.
- **AI depends on a configured OpenAI key.** Without `OPENAI_API_KEY`, generate returns HTTP 503.
- **Seed runs only on an empty database.** An existing `backend/bailanysta.db` will not pick up new seed posts.
- **No cloud deployment or CI in this repo.** No Dockerfile, GitHub Actions, or hosted environment is defined.
- **iOS tests cover ViewModels, not UI or `APIClient`.** Backend tests mock the AI provider; they do not call OpenAI.

## Setup

### 1. Get the project

```bash
git clone <repository-url>
cd Bailanysta
```

### 2–5. Backend

Python 3.9+ is required.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
```

Edit `backend/.env` if needed:

```bash
DATABASE_URL=sqlite:///./bailanysta.db
OPENAI_API_KEY=
```

Leave `OPENAI_API_KEY` empty unless you want AI compose. Then:

```bash
uvicorn app.main:app --reload
```

API: [http://127.0.0.1:8000](http://127.0.0.1:8000)  
OpenAPI: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

On first launch with an empty database the API creates tables and seeds three users (`aikhan`, `dana`, `nurlan`) and a few posts. The iOS app acts as user **1** (`aikhan`).

### 6–8. iOS

1. Open `iOS/Bailanysta/Bailanysta.xcodeproj` in Xcode.
2. Confirm the API base URL in `Bailanysta/Core/Networking/APIConfig.swift`:

   ```swift
   static let baseURL = URL(string: "http://127.0.0.1:8000")!
   static let currentUserID = 1
   ```

3. Select an **iOS Simulator** (iOS 17 or later).
4. Run the **Bailanysta** scheme.

Keep uvicorn running while using the app. `Info.plist` allows local HTTP via `NSAllowsLocalNetworking`.

## AI Setup

1. Create an OpenAI API key in the OpenAI dashboard.
2. Set it only in `backend/.env`:

   ```bash
   OPENAI_API_KEY=your_openai_api_key_here
   ```

3. Restart uvicorn.

Flow:

```text
Compose screen
  → POST /ai/generate-post  { "prompt": "..." }  (header X-User-Id)
  → FastAPI validates prompt (1–1000 chars, not blank)
  → ai_service.generate_post_text reads OPENAI_API_KEY
  → POST https://api.openai.com/v1/chat/completions  (gpt-4o-mini)
  → FastAPI returns { "text": "..." }
  → Editor shows the text; the user can edit it, then Post/Save as usual
```

**Never put the OpenAI key in the iOS target, `Info.plist`, or `APIConfig`.** The client only talks to FastAPI.

If the key is missing, the API responds `503` with `AI is not configured`. Provider failures are `502`.

## Testing

### Backend

```bash
cd backend
source .venv/bin/activate
pytest -q
```

Coverage includes post CRUD, ownership (`403`), validation, likes, comments, search, users, and AI (provider mocked).

### iOS

In Xcode: **Product → Test** (scheme **Bailanysta**).

From the command line:

```bash
cd iOS/Bailanysta
xcodebuild test -scheme Bailanysta -destination 'platform=iOS Simulator,name=iPhone 17'
```

Use a Simulator name that exists on your machine. Tests stub `PostService` / `AIService` and cover feed load success/failure, create/edit post, delete, and AI generate success/error.

## Deployment

This repository does **not** include a hosted backend, Docker image, or CI pipeline. Day-to-day use is local uvicorn + Simulator.

To run the API as a long-lived process on a machine you control:

```bash
cd backend
source .venv/bin/activate
pip install -r requirements.txt
# set DATABASE_URL and OPENAI_API_KEY in the environment (not in git)
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Then point `APIConfig.baseURL` at that host (HTTPS in any real deployment). SQLite on a single instance is the current database; a multi-instance or public deployment should use a server database and real authentication before exposing the API.

## Future Improvements

- Replace `X-User-Id` with real sign-in (tokens in Keychain)
- Paginate feed, profile, comments, and search
- Host the API with HTTPS and a managed database
- Add CI (pytest + `xcodebuild test`)
- Media attachments, if the product needs more than text
- Open another user’s profile from the feed
- Comment edit/delete and a clearer “switch user” for demos

## API (reference)

| Method | Path | Auth |
|---|---|---|
| `GET` | `/posts` | optional `X-User-Id` (for `is_liked`) |
| `POST` | `/posts` | required |
| `PATCH` | `/posts/{id}` | required, author only |
| `DELETE` | `/posts/{id}` | required, author only |
| `POST` / `DELETE` | `/posts/{id}/like` | required |
| `GET` / `POST` | `/posts/{id}/comments` | GET public; POST required |
| `GET` | `/users/{id}` | no |
| `GET` | `/users/{id}/posts` | optional `X-User-Id` |
| `GET` | `/search?q=` | optional `X-User-Id` |
| `POST` | `/ai/generate-post` | required |
