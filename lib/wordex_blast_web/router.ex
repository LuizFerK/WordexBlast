defmodule WordexBlastWeb.Router do
  use WordexBlastWeb, :router

  import WordexBlastWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WordexBlastWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/", WordexBlastWeb do
    pipe_through [:browser]

    get "/", HomeController, :home
    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{WordexBlastWeb.UserAuth, :mount_current_user}] do
      live "/app", AppLive
      live "/play/:room_id", PlayLive

      live "/users/confirm/:token", Accounts.UserConfirmationLive, :edit
      live "/users/confirm", Accounts.UserConfirmationInstructionsLive, :new
    end
  end

  # Authenticated routes
  scope "/", WordexBlastWeb.Accounts do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{WordexBlastWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  # Authentication routes
  scope "/", WordexBlastWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{WordexBlastWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", Accounts.UserRegistrationLive, :new
      live "/users/log_in", Accounts.UserLoginLive, :new
      live "/users/reset_password", Accounts.UserForgotPasswordLive, :new
      live "/users/reset_password/:token", Accounts.UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  # Dev routes
  if Application.compile_env(:wordex_blast, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WordexBlastWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
