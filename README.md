# MonApp

Application web construite avec **Phoenix Framework** (Elixir) incluant :
- API REST avec authentification JWT
- Interface temps réel avec LiveView
- Gestion des utilisateurs et des posts

## Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- **Elixir** >= 1.15 ([Guide d'installation](https://elixir-lang.org/install.html))
- **Erlang** >= 26
- **PostgreSQL** >= 14 ([Télécharger](https://www.postgresql.org/download/))
- **Node.js** >= 18 (pour les assets)

### Vérifier les versions

```bash
elixir --version
psql --version
node --version
```

## Installation

### 1. Cloner le projet

```bash
git clone <url-du-repo>
cd mon_app
```

### 2. Installer les dépendances

```bash
mix deps.get
```

### 3. Configurer la base de données

Modifier le fichier `config/dev.exs` avec vos identifiants PostgreSQL :

```elixir
config :mon_app, MonApp.Repo,
  username: "votre_username",
  password: "votre_password",
  hostname: "localhost",
  database: "mon_app_dev"
```

### 4. Créer et migrer la base de données

```bash
mix ecto.setup
```

Ou séparément :

```bash
mix ecto.create
mix ecto.migrate
```

### 5. Installer les assets (CSS/JS)

```bash
mix assets.setup
```

### 6. Lancer le serveur

```bash
mix phx.server
```

L'application est accessible sur [http://localhost:4000](http://localhost:4000)

## Utilisation

### Interface Web (LiveView)

| URL | Description |
|-----|-------------|
| `/register` | Créer un compte |
| `/login` | Se connecter |
| `/posts` | Voir/créer des posts (temps réel) |

### API REST

#### Authentification

```bash
# Inscription
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user": {"name": "Nom", "email": "email@test.com", "password": "secret123"}}'

# Connexion
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "email@test.com", "password": "secret123"}'
```

#### Endpoints API

| Méthode | URL | Description | Auth |
|---------|-----|-------------|------|
| GET | `/api/users` | Liste des utilisateurs | Non |
| GET | `/api/users/:id` | Détail d'un utilisateur | Non |
| GET | `/api/posts` | Liste des posts | Non |
| GET | `/api/posts/:id` | Détail d'un post | Non |
| POST | `/api/posts` | Créer un post | **Oui** |
| PUT | `/api/posts/:id` | Modifier un post | **Oui** |
| DELETE | `/api/posts/:id` | Supprimer un post | **Oui** |
| GET | `/api/me` | Utilisateur connecté | **Oui** |

#### Utiliser le token JWT

```bash
curl http://localhost:4000/api/me \
  -H "Authorization: Bearer VOTRE_TOKEN_JWT"
```

## Structure du projet

```
lib/
├── mon_app/                    # Logique métier
│   ├── accounts/              # Gestion utilisateurs
│   │   └── user.ex            # Schema User
│   ├── blog/                  # Gestion posts
│   │   └── post.ex            # Schema Post
│   ├── accounts.ex            # Context Accounts
│   ├── blog.ex                # Context Blog
│   └── guardian.ex            # Config JWT
│
└── mon_app_web/               # Interface web
    ├── controllers/           # API REST
    ├── live/                  # LiveView (temps réel)
    │   ├── auth/             # Login/Register
    │   └── posts_live.ex     # Page posts
    ├── plugs/                # Middleware auth
    └── router.ex             # Routes
```

## Fonctionnalités

### Authentification
- Inscription avec validation (email unique, mot de passe min 6 caractères)
- Connexion avec session (LiveView) ou JWT (API)
- Protection des routes

### Posts
- CRUD complet
- Relation User → Posts (un utilisateur a plusieurs posts)
- Temps réel : les nouveaux posts apparaissent instantanément
- Seul l'auteur peut supprimer son post

### Temps réel (LiveView)
- WebSocket automatique
- PubSub pour synchroniser tous les clients
- Pas de JavaScript à écrire

## Commandes utiles

```bash
# Lancer le serveur
mix phx.server

# Lancer avec console interactive
iex -S mix phx.server

# Créer une migration
mix ecto.gen.migration nom_migration

# Exécuter les migrations
mix ecto.migrate

# Annuler la dernière migration
mix ecto.rollback

# Réinitialiser la base de données
mix ecto.reset

# Lancer les tests
mix test

# Vérifier le code (linter)
mix format
mix credo
```

## Configuration Production

### Variables d'environnement

```bash
export DATABASE_URL="postgresql://user:pass@host/db"
export SECRET_KEY_BASE="votre_cle_secrete_64_chars"
export PHX_HOST="votre-domaine.com"
```

### Générer une clé secrète

```bash
mix phx.gen.secret
```

### Build de production

```bash
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
```

## Technologies utilisées

- **Elixir** - Langage de programmation
- **Phoenix** - Framework web
- **Ecto** - ORM / Query builder
- **LiveView** - Interface temps réel
- **Guardian** - Authentification JWT
- **Bcrypt** - Hashage des mots de passe
- **PostgreSQL** - Base de données
- **Tailwind CSS** - Styles

## Ressources

- [Documentation Phoenix](https://hexdocs.pm/phoenix)
- [Documentation Elixir](https://elixir-lang.org/docs.html)
- [Documentation Ecto](https://hexdocs.pm/ecto)
- [Documentation LiveView](https://hexdocs.pm/phoenix_live_view)
- [Forum Elixir](https://elixirforum.com)

## Licence

MIT
