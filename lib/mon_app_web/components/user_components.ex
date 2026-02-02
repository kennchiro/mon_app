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

  def user_tabs(assigns) do
    ~H"""
    <div class="tabs tabs-boxed bg-base-100 p-1 mb-6">
      <button
        phx-click="change_tab"
        phx-value-tab="friends"
        class={"tab #{if @active_tab == :friends, do: "tab-active"}"}
      >
        Mes amis
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
      <div class="card-body flex-row items-center gap-4 py-4">
        <PostComponents.user_avatar name={@user.name} />

        <div class="flex-1">
          <h3 class="font-semibold">{@user.name}</h3>
          <p class="text-sm text-base-content/50">{@user.email}</p>
        </div>

        <.action_buttons user={@user} type={@type} />
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
      phx-click="remove_friend"
      phx-value-id={@user.id}
      class="btn btn-ghost btn-sm text-error"
      data-confirm="Retirer cet ami ?"
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7a4 4 0 11-8 0 4 4 0 018 0zM9 14a6 6 0 00-6 6v1h12v-1a6 6 0 00-6-6zM21 12h-6" />
      </svg>
    </button>
    """
  end

  defp action_buttons(%{type: :pending} = assigns) do
    ~H"""
    <div class="flex gap-2">
      <button
        phx-click="accept_request"
        phx-value-id={@user.friendship_id}
        class="btn btn-primary btn-sm"
      >
        Accepter
      </button>
      <button
        phx-click="reject_request"
        phx-value-id={@user.friendship_id}
        class="btn btn-ghost btn-sm"
      >
        Refuser
      </button>
    </div>
    """
  end

  defp action_buttons(%{type: :sent} = assigns) do
    ~H"""
    <button
      phx-click="cancel_request"
      phx-value-id={@user.id}
      class="btn btn-ghost btn-sm text-error"
      data-confirm="Annuler cette demande ?"
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

  defp empty_users(%{type: :friend} = assigns) do
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

  defp empty_users(%{type: :pending} = assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50 py-10">
        <div class="text-4xl mb-2">📬</div>
        <p>Aucune demande d'ami en attente.</p>
      </div>
    </div>
    """
  end

  defp empty_users(%{type: :sent} = assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50 py-10">
        <div class="text-4xl mb-2">📤</div>
        <p>Aucune demande envoyée en attente.</p>
      </div>
    </div>
    """
  end

  defp empty_users(%{type: :discover} = assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50 py-10">
        <div class="text-4xl mb-2">🎉</div>
        <p>Vous connaissez tout le monde !</p>
      </div>
    </div>
    """
  end
end
