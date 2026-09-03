# SendAGift Mobile

Flutter **customer** app for the SendAGift platform (companion to `send-agift-backend` and
`send-agift-frontend`). Sellers and admins are web-only — there are no seller or admin
surfaces in this app.

## Getting started

```bash
cp .env.example .env   # point API_BASE_URL at your backend
flutter pub get
flutter run
```

## Guest-first, like eBay or AliExpress

The app opens straight onto the storefront. There is **no login wall and no auth redirect**
in the router. Guests can:

- browse the catalog, search, and filter by occasion
- open any product page
- save gifts to a wishlist (stored on device)
- add to cart and change quantities (stored on device)

An account is requested at exactly two points — **checkout** and **order history** — and the
prompt explains what signing in adds rather than blocking the screen.

## Screens

| Screen | Route | Notes |
| --- | --- | --- |
| Home | `/` | Hero, trust bar, occasion categories, live gift shelf, offer banner, testimonials |
| Explore | `/explore` | Full catalog with search + category chips |
| Gift detail | `/gift/:id` | Hero image transition, shop line, sticky add-to-cart bar |
| Saved | `/saved` | Wishlist grid, works for guests |
| Cart | `/cart` | Line items, quantity steppers, subtotal/shipping/total |
| Checkout | `/checkout` | Sign-in gate + order summary |
| Orders | `/orders` | Sign-in gate for guests |
| Account | `/account` | Guest or signed-in header, customer menu |
| Sign in / Register | `/login`, `/register` | Customer endpoints only |

## Design system

Ported from the web frontend so both clients read as one brand:

- **Colour** — the olive marketplace palette, converted from the OKLCH tokens in the web's
  `src/index.css` (primary `#445427`, warm near-white ground, cream section bands).
- **Type** — Fraunces for display headings, Geist for UI text. Both are bundled as static
  TTFs in `assets/fonts/`, so there is no runtime font fetch.
- **Shape** — the web's `--radius` scale, pill buttons, soft olive-tinted card shadows.

Tokens live in [lib/core/theme/](lib/core/theme/); shared components in
[lib/core/widgets/](lib/core/widgets/).

## Data

The catalog reads the public, unauthenticated marketplace endpoints — that is what makes
guest browsing possible:

- `GET /shops` — active shops
- `GET /shops/{id}/products?customer_type=personal` — published products

`AppConfig` rewrites a `localhost` host to `10.0.2.2` on Android, because in the
Android emulator `localhost` is the emulated device itself and the host machine is only
reachable through that alias. A physical device needs the machine's LAN IP in `.env`.

Prices arrive in minor units with a currency code and are formatted through
[core/utils/money.dart](lib/core/utils/money.dart), mirroring the web's `lib/money.ts`.
Currencies sharing a symbol (USD, AUD, NZD, CAD, SGD all render `$`) are shown with their
ISO code instead — `AUD 25.00` — so a cross-border price is never ambiguous.
When the backend is **unreachable**, the storefront falls back to a sample shelf so the app
stays usable. A successful-but-empty response is not faked: if no shop has published yet,
the real "nothing published" state is shown, so sample data can never be mistaken for
live catalog.

Auth uses the customer endpoints only: `POST /customers/login`, `POST /customers/register`,
`GET /customers/me`.

## Project structure

```
lib/
  app/                  # App widget, bottom-nav shell
  core/
    config/             # Environment config (AppConfig)
    network/            # ApiClient (Dio), secure token storage, providers
    router/             # go_router routes
    theme/              # Colours, typography, ThemeData
    errors/             # Shared exception types
    utils/              # Money formatting
    widgets/            # Shared components
  features/
    auth/               # Customer login + registration
    home/               # Storefront landing
    products/           # Catalog: models, repository, explore, detail
    cart/               # Local cart + checkout
    saved/              # Wishlist
    orders/             # Order history
    profile/            # Account hub
```

Each feature is `data/` + `domain/` + `presentation/` so they can grow independently.

## Stack

- **State** — `flutter_riverpod`
- **Routing** — `go_router` (`StatefulShellRoute` bottom nav)
- **Network** — `dio` via `ApiClient`
- **Storage** — `flutter_secure_storage` (tokens), `shared_preferences` (cart, wishlist)
- **Images** — `cached_network_image` with shimmer placeholders

## Not yet built

Delivery address, recipient selection, and payment on the checkout screen; live order list
and tracking; syncing the local wishlist/cart to the server after sign-in.
