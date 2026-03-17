defmodule MonAppWeb.UserComponents do
  @moduledoc """
  Composants réutilisables pour les utilisateurs.
  """
  use Phoenix.Component

  alias MonAppWeb.PostComponents

  # ============== TABS ==============

  attr :active_tab, :atom, required: true
  attr :pending_count, :integer, default: 0
  attr :sent_count, :integer, default: 0
  attr :friends_count, :integer, default: 0

  def user_tabs(assigns) do
    ~H"""
    <div class="tabs tabs-boxed bg-base-100 p-1 mb-6">
      <button
        phx-click="change_tab"
        phx-value-tab="friends"
        class={"tab #{if @active_tab == :friends, do: "tab-active"}"}
      >
        Mes amis
        <span :if={@friends_count > 0} class="badge badge-ghost badge-sm ml-1">
          {@friends_count}
        </span>
      </button>
      <button
        phx-click="change_tab"
        phx-value-tab="pending"
        class={"tab #{if @active_tab == :pending, do: "tab-active"}"}
      >
        Demandes
        <span :if={@pending_count > 0} class="badge badge-primary badge-sm ml-2">
          {@pending_count}
        </span>
      </button>
      <button
        phx-click="change_tab"
        phx-value-tab="sent"
        class={"tab #{if @active_tab == :sent, do: "tab-active"}"}
      >
        Envoyées
        <span :if={@sent_count > 0} class="badge badge-ghost badge-sm ml-2">
          {@sent_count}
        </span>
      </button>
      <button
        phx-click="change_tab"
        phx-value-tab="discover"
        class={"tab #{if @active_tab == :discover, do: "tab-active"}"}
      >
        Découvrir
      </button>
    </div>
    """
  end

  # ============== USER LIST ==============

  attr :users, :list, required: true
  attr :type, :atom, required: true  # :friend, :pending, :discover
  attr :current_user, :map, required: true

  def user_list(assigns) do
    ~H"""
    <div class="space-y-3">
      <.empty_users :if={@users == []} type={@type} />

      <.user_card
        :for={user <- @users}
        user={user}
        type={@type}
        current_user={@current_user}
      />
    </div>
    """
  end

  # ============== USER CARD ==============

  attr :user, :map, required: true
  attr :type, :atom, required: true
  attr :current_user, :map, required: true

  def user_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body p-3 sm:p-4">
        <div class="flex items-center gap-3">
          <PostComponents.profile_link user_id={@user.id}>
            <PostComponents.user_avatar name={@user.name} avatar={@user.avatar} />
          </PostComponents.profile_link>

          <div class="flex-1 min-w-0">
            <PostComponents.profile_link user_id={@user.id}>
              <h3 class="font-semibold hover:underline cursor-pointer truncate">{@user.name}</h3>
            </PostComponents.profile_link>
            <p class="text-sm text-base-content/50 truncate">{@user.email}</p>
          </div>

          <.action_buttons :if={@type in [:friend, :discover, :sent]} user={@user} type={@type} />

          <!-- Pending: desktop only inline buttons -->
          <div :if={@type == :pending} class="hidden sm:flex gap-2">
            <button phx-click="accept_request" phx-value-id={@user.friendship_id} class="btn btn-primary btn-sm">
              Accepter
            </button>
            <button phx-click="reject_request" phx-value-id={@user.friendship_id} class="btn btn-ghost btn-sm">
              Refuser
            </button>
          </div>
        </div>

        <!-- Pending: mobile only buttons below -->
        <div :if={@type == :pending} class="flex gap-2 mt-2 ml-12 sm:hidden">
          <button phx-click="accept_request" phx-value-id={@user.friendship_id} class="btn btn-primary btn-sm flex-1">
            Accepter
          </button>
          <button phx-click="reject_request" phx-value-id={@user.friendship_id} class="btn btn-ghost btn-sm flex-1">
            Refuser
          </button>
        </div>
      </div>
    </div>
    """
  end

  # ============== ACTION BUTTONS ==============

  attr :user, :map, required: true
  attr :type, :atom, required: true

  defp action_buttons(%{type: :friend} = assigns) do
    ~H"""
    <button
      phx-click="show_remove_friend_confirm"
      phx-value-id={@user.id}
      phx-value-name={@user.name}
      class="btn btn-ghost btn-sm text-error"
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7a4 4 0 11-8 0 4 4 0 018 0zM9 14a6 6 0 00-6 6v1h12v-1a6 6 0 00-6-6zM21 12h-6" />
      </svg>
    </button>
    """
  end

  # pending actions are rendered directly in user_card for responsive layout

  defp action_buttons(%{type: :sent} = assigns) do
    ~H"""
    <button
      phx-click="show_cancel_request_confirm"
      phx-value-id={@user.id}
      phx-value-name={@user.name}
      class="btn btn-ghost btn-sm text-error"
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
      Annuler
    </button>
    """
  end

  defp action_buttons(%{type: :discover} = assigns) do
    ~H"""
    <button
      phx-click="send_request"
      phx-value-id={@user.id}
      class="btn btn-primary btn-sm"
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
      </svg>
      Ajouter
    </button>
    """
  end

  # ============== EMPTY STATES ==============

  attr :type, :atom, required: true

  def empty_users(%{type: :friend} = assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50 py-10">
        <div class="text-4xl mb-2">👥</div>
        <p>Vous n'avez pas encore d'amis.</p>
        <p class="text-sm">Découvrez des utilisateurs à ajouter !</p>
      </div>
    </div>
    """
  end

  def empty_users(%{type: :pending} = assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50 py-10">
        <div class="text-4xl mb-2">📬</div>
        <p>Aucune demande d'ami en attente.</p>
      </div>
    </div>
    """
  end

  def empty_users(%{type: :sent} = assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50 py-10">
        <div class="text-4xl mb-2">📤</div>
        <p>Aucune demande envoyée en attente.</p>
      </div>
    </div>
    """
  end

  def empty_users(%{type: :discover} = assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50 py-10">
        <div class="text-4xl mb-2">🎉</div>
        <p>Vous connaissez tout le monde !</p>
      </div>
    </div>
    """
  end

  def empty_users(%{type: :search} = assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50 py-10">
        <div class="text-4xl mb-2">🔍</div>
        <p>Aucun résultat trouvé.</p>
      </div>
    </div>
    """
  end
end
