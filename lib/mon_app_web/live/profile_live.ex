defmodule MonAppWeb.ProfileLive do
  use MonAppWeb, :live_view

  alias MonApp.Social
  alias MonApp.Chat
  alias MonApp.Accounts
  alias MonAppWeb.Presence

  import MonAppWeb.Navbar

  # ============== LIFECYCLE ==============

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    user_id = user.id

    if connected?(socket) do
      # Tracker la présence de l'utilisateur
      {:ok, _} = Presence.track(self(), "users:online", to_string(user_id), %{
        user_id: user_id,
        name: user.name,
        online_at: System.system_time(:second)
      })

      # S'abonner aux notifications de nouveaux messages
      Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user_id}")
    end

    pending_count = length(Social.list_pending_requests(user_id))
    unread_messages_count = Chat.count_total_unread(user_id)

    {:ok,
     socket
     |> assign(:pending_requests_count, pending_count)
     |> assign(:unread_messages_count, unread_messages_count)
     |> allow_upload(:avatar,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 1,
       max_file_size: 5_000_000,
       auto_upload: true
     )}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    # Vérifier s'il y a un upload en cours
    has_upload = length(assigns.uploads.avatar.entries) > 0
    upload_ready = has_upload && Enum.all?(assigns.uploads.avatar.entries, & &1.done?)
    upload_in_progress = has_upload && Enum.any?(assigns.uploads.avatar.entries, fn e -> e.progress > 0 && e.progress < 100 end)

    assigns =
      assigns
      |> assign(:has_upload, has_upload)
      |> assign(:upload_ready, upload_ready)
      |> assign(:upload_in_progress, upload_in_progress)

    ~H"""
    <div class="min-h-screen bg-base-200">
      <.navbar current_user={@current_user} current_path="/profile" pending_requests_count={@pending_requests_count} unread_messages_count={@unread_messages_count} />

      <main class="max-w-4xl mx-auto p-6">
        <div class="card bg-base-100 shadow-sm">
          <div class="card-body">
            <!-- Header profil -->
            <div class="flex flex-col sm:flex-row items-center gap-6">
              <!-- Avatar section -->
              <div class="flex flex-col items-center gap-3">
                <!-- Avatar actuel OU preview de l'upload -->
                <div class="relative group">
                  <%= if @has_upload do %>
                    <!-- Preview de la nouvelle image -->
                    <%= for entry <- @uploads.avatar.entries do %>
                      <div class="relative">
                        <div class="w-28 h-28 rounded-full overflow-hidden ring-4 ring-primary">
                          <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                        </div>
                        <!-- Progress overlay -->
                        <div :if={entry.progress > 0 && entry.progress < 100} class="absolute inset-0 rounded-full bg-black/50 flex items-center justify-center">
                          <div class="radial-progress text-primary-content" style={"--value:#{entry.progress}; --size:3rem;"} role="progressbar">
                            {entry.progress}%
                          </div>
                        </div>
                        <!-- Check icon when done -->
                        <div :if={entry.done?} class="absolute inset-0 rounded-full bg-success/20 flex items-center justify-center">
                          <div class="bg-success text-success-content rounded-full p-2">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                            </svg>
                          </div>
                        </div>
                      </div>
                      <!-- Erreurs -->
                      <p :for={err <- upload_errors(@uploads.avatar, entry)} class="text-error text-sm mt-2">
                        {error_to_string(err)}
                      </p>
                    <% end %>
                  <% else %>
                    <!-- Avatar actuel ou placeholder -->
                    <div class="w-28 h-28 rounded-full overflow-hidden bg-primary grid place-items-center ring-4 ring-base-200">
                      <%= if @current_user.avatar do %>
                        <img
                          src={"/uploads/avatars/#{@current_user.avatar}"}
                          alt="Avatar"
                          class="w-full h-full object-cover"
                        />
                      <% else %>
                        <span class="text-primary-content text-4xl font-bold leading-none">
                          {String.first(@current_user.name)}
                        </span>
                      <% end %>
                    </div>

                    <!-- Overlay pour changer l'avatar (seulement quand pas d'upload) -->
                    <label
                      for={@uploads.avatar.ref}
                      class="absolute inset-0 rounded-full bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                    >
                      <div class="text-center text-white">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                        <span class="text-xs mt-1">Modifier</span>
                      </div>
                    </label>

                    <!-- Bouton supprimer si avatar existant -->
                    <button
                      :if={@current_user.avatar}
                      type="button"
                      phx-click="delete_avatar"
                      class="absolute -bottom-1 -right-1 btn btn-circle btn-xs btn-error"
                      title="Supprimer l'avatar"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  <% end %>
                </div>

                <!-- Input file caché -->
                <form phx-change="validate_avatar" phx-submit="save_avatar" class="hidden">
                  <.live_file_input upload={@uploads.avatar} class="hidden" />
                </form>

                <!-- Boutons d'action pour l'upload -->
                <div :if={@has_upload} class="flex gap-2">
                  <button
                    type="button"
                    phx-click="save_avatar"
                    disabled={!@upload_ready}
                    class={"btn btn-primary btn-sm " <> if @upload_ready, do: "", else: "btn-disabled"}
                  >
                    <%= if @upload_in_progress do %>
                      <span class="loading loading-spinner loading-xs"></span>
                      Upload...
                    <% else %>
                      Enregistrer
                    <% end %>
                  </button>
                  <button type="button" phx-click="cancel_avatar" class="btn btn-ghost btn-sm">
                    Annuler
                  </button>
                </div>
              </div>

              <!-- Infos utilisateur -->
              <div class="text-center sm:text-left">
                <h1 class="text-2xl font-bold">{@current_user.name}</h1>
                <p class="text-base-content/60">{@current_user.email}</p>
                <p class="text-sm text-base-content/40 mt-1">
                  Membre depuis {Calendar.strftime(@current_user.inserted_at, "%B %Y")}
                </p>
              </div>
            </div>

            <div class="divider"></div>

            <!-- Informations -->
            <div class="grid gap-4">
              <div>
                <label class="text-sm text-base-content/60">Nom</label>
                <p class="font-medium">{@current_user.name}</p>
              </div>
              <div>
                <label class="text-sm text-base-content/60">Email</label>
                <p class="font-medium">{@current_user.email}</p>
              </div>
              <div :if={@current_user.age}>
                <label class="text-sm text-base-content/60">Âge</label>
                <p class="font-medium">{@current_user.age} ans</p>
              </div>
            </div>

            <div class="divider"></div>

            <!-- Instructions -->
            <div class="text-center text-base-content/50">
              <p class="text-sm">Survolez votre photo de profil pour la modifier.</p>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("validate_avatar", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_avatar", _params, socket) do
    user = socket.assigns.current_user
    entries = socket.assigns.uploads.avatar.entries

    # Vérifier que l'upload est terminé
    if Enum.empty?(entries) || !Enum.all?(entries, & &1.done?) do
      {:noreply, put_flash(socket, :error, "Veuillez attendre la fin de l'upload")}
    else
      # Sauvegarder le fichier uploadé
      uploaded_files =
        consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
          # Générer un nom de fichier unique
          ext = Path.extname(entry.client_name)
          filename = "avatar_#{user.id}_#{System.unique_integer([:positive])}#{ext}"
          dest = Path.join(Accounts.avatars_dir(), filename)

          # S'assurer que le répertoire existe
          File.mkdir_p!(Path.dirname(dest))

          # Copier le fichier
          File.cp!(path, dest)
          {:ok, filename}
        end)

      case uploaded_files do
        [filename] ->
          case Accounts.update_avatar(user, filename) do
            {:ok, updated_user} ->
              {:noreply,
               socket
               |> assign(:current_user, updated_user)
               |> put_flash(:info, "Photo de profil mise à jour")}

            {:error, _changeset} ->
              {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour")}
          end

        [] ->
          {:noreply, put_flash(socket, :error, "Aucun fichier à enregistrer")}
      end
    end
  end

  @impl true
  def handle_event("cancel_avatar", _params, socket) do
    # Annuler tous les uploads en cours
    socket =
      Enum.reduce(socket.assigns.uploads.avatar.entries, socket, fn entry, acc ->
        cancel_upload(acc, :avatar, entry.ref)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_avatar", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.delete_avatar(user) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> put_flash(:info, "Photo de profil supprimée")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
    end
  end

  # ============== PUBSUB HANDLERS ==============

  @impl true
  def handle_info({:new_message, _message}, socket) do
    # Incrémenter le compteur de messages non lus
    user_id = socket.assigns.current_user.id
    unread_count = Chat.count_total_unread(user_id)
    {:noreply, assign(socket, :unread_messages_count, unread_count)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # ============== HELPERS ==============

  defp error_to_string(:too_large), do: "Fichier trop volumineux (max 5 Mo)"
  defp error_to_string(:not_accepted), do: "Type de fichier non accepté"
  defp error_to_string(:too_many_files), do: "Une seule image autorisée"
  defp error_to_string(_), do: "Erreur de téléchargement"
end
