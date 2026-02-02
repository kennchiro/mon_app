defmodule MonAppWeb.Router do
  use MonAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MonAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MonAppWeb.FetchCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Pipeline pour vérifier le token JWT (optionnel)
  pipeline :auth do
    plug MonAppWeb.AuthPipeline
  end

  # Pipeline pour routes protégées (token obligatoire)
  pipeline :ensure_auth do
    plug MonAppWeb.EnsureAuth
  end

  # ============== PAGES PUBLIQUES ==============

  scope "/", MonAppWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # ============== AUTH LIVEVIEW (guests only) ==============

  live_session :guest,
    on_mount: [{MonAppWeb.LiveAuth, :redirect_if_authenticated}] do
    scope "/", MonAppWeb do
      pipe_through :browser

      live "/register", RegisterLive
      live "/login", LoginLive
    end
  end

  # ============== SESSION CONTROLLER ==============

  scope "/auth", MonAppWeb do
    pipe_through :browser

    get "/login-session", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  # ============== PAGES PROTÉGÉES (auth required) ==============

  live_session :authenticated,
    on_mount: [{MonAppWeb.LiveAuth, :require_authenticated_user}] do
    scope "/", MonAppWeb do
      pipe_through :browser

      live "/posts", PostsLive
    end
  end

  # ============== API PUBLIQUES ==============

  scope "/auth", MonAppWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
  end

  scope "/api", MonAppWeb do
    pipe_through [:api, :auth]

    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    get "/users/:user_id/posts", PostController, :index_by_user
    get "/posts", PostController, :index
    get "/posts/:id", PostController, :show
  end

  # ============== API PROTÉGÉES ==============

  scope "/api", MonAppWeb do
    pipe_through [:api, :auth, :ensure_auth]

    get "/me", AuthController, :me
    post "/users", UserController, :create
    put "/users/:id", UserController, :update
    patch "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete
    post "/posts", PostController, :create
    put "/posts/:id", PostController, :update
    patch "/posts/:id", PostController, :update
    delete "/posts/:id", PostController, :delete
  end

  # ============== DEV ROUTES ==============

  if Application.compile_env(:mon_app, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MonAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
