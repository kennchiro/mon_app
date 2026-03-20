defmodule MonAppWeb.PostComponents do
  @moduledoc """
  Composants réutilisables pour les posts.
  """
  use Phoenix.Component
  use MonAppWeb, :verified_routes

  import MonAppWeb.TimeHelpers

  # ============== POST FORM TRIGGER ==============

  attr :current_user, :map, required: true

  def post_form_trigger(assigns) do
    ~H"""
    <div class="bg-base-100 rounded-xl shadow-sm mb-4 overflow-hidden">
      <!-- Row 1: Post standard -->
      <div class="p-3 cursor-pointer hover:bg-base-200/50 transition-colors" phx-click="open_post_modal">
        <div class="flex items-center gap-2.5">
          <.user_avatar name={@current_user.name} avatar={@current_user.avatar} size="w-9 h-9" />
          <div class="flex-1 bg-base-200 hover:bg-base-300 rounded-full px-4 py-2 text-[15px] text-base-content/50 transition-colors">
            Quoi de neuf, {@current_user.name |> String.split() |> List.first()} ?
          </div>
        </div>
      </div>

      <!-- Separator -->
      <div class="border-t border-base-200"></div>

      <!-- Row 2: Two equal buttons -->
      <div class="flex">
        <!-- Date button -->
        <button type="button" phx-click="open_date_modal" class="flex-1 py-2.5 flex items-center justify-center gap-2 text-[13px] font-semibold text-base-content/60 hover:bg-transparent transition-all group">
          <span class="text-lg group-hover:scale-110 transition-transform">💘</span>
          <span class="bg-gradient-to-r from-pink-500 to-rose-500 bg-clip-text text-transparent font-bold">Proposer un Date</span>
        </button>

        <!-- Divider vertical -->
        <div class="w-px bg-base-200"></div>

        <!-- Post button -->
        <button type="button" phx-click="open_post_modal" class="flex-1 py-2.5 flex items-center justify-center gap-2 text-[13px] font-semibold text-base-content/60 hover:bg-base-200 transition-colors">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
          </svg>
          <span>Publication</span>
        </button>
      </div>
    </div>
    """
  end

  # ============== POST FORM MODAL ==============

  attr :form, :map, required: true
  attr :uploads, :map, required: true
  attr :current_user, :map, required: true

  def post_form_modal(assigns) do
    ~H"""
    <!-- Overlay -->
    <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <!-- Modal -->
      <div
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-lg max-h-[90vh] flex flex-col"
        phx-click-away="close_post_modal"
      >
        <!-- Header -->
        <div class="flex items-center justify-between p-4 border-b border-white/20">
          <div></div>
          <h3 class="text-xl font-bold">Créer une publication</h3>
          <button
            type="button"
            phx-click="close_post_modal"
            class="btn btn-ghost btn-sm btn-circle"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Body -->
        <.form for={@form} phx-submit="save" phx-change="validate" class="flex flex-col flex-1 overflow-hidden">
          <div class="p-4 flex-1 overflow-y-auto space-y-4">
            <!-- User info + visibility -->
            <div class="flex items-center gap-3">
              <.user_avatar name={@current_user.name} avatar={@current_user.avatar} />
              <div>
                <div class="font-semibold">{@current_user.name}</div>
                <!-- Visibility dropdown -->
                <div class="dropdown dropdown-bottom">
                  <div tabindex="0" role="button" class="btn btn-xs btn-ghost gap-1 -ml-2">
                    <.visibility_icon visibility={@form[:visibility].value || "public"} />
                    <span class="text-xs">{visibility_label(@form[:visibility].value || "public")}</span>
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                  <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[60] w-52 p-2 shadow-lg border border-white/20">
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="post[visibility]" value="public" checked={(@form[:visibility].value || "public") == "public"} class="radio radio-sm" />
                        <.visibility_icon visibility="public" />
                        <div>
                          <div class="font-medium text-sm">Public</div>
                          <div class="text-xs text-base-content/50">Tout le monde</div>
                        </div>
                      </label>
                    </li>
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="post[visibility]" value="friends" checked={@form[:visibility].value == "friends"} class="radio radio-sm" />
                        <.visibility_icon visibility="friends" />
                        <div>
                          <div class="font-medium text-sm">Amis</div>
                          <div class="text-xs text-base-content/50">Vos amis uniquement</div>
                        </div>
                      </label>
                    </li>
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="post[visibility]" value="private" checked={@form[:visibility].value == "private"} class="radio radio-sm" />
                        <.visibility_icon visibility="private" />
                        <div>
                          <div class="font-medium text-sm">Moi uniquement</div>
                          <div class="text-xs text-base-content/50">Privé</div>
                        </div>
                      </label>
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <!-- Title input -->
            <div>
              <input
                type="text"
                name="post[title]"
                value={@form[:title].value}
                class="input input-ghost w-full text-lg font-medium focus:outline-none px-0"
                placeholder="Titre de votre publication..."
                phx-debounce="300"
              />
              <.field_error field={@form[:title]} />
            </div>

            <!-- Body textarea -->
            <textarea
              name="post[body]"
              class="textarea textarea-ghost w-full min-h-[100px] text-base resize-none focus:outline-none px-0"
              placeholder={"Quoi de neuf, #{@current_user.name |> String.split() |> List.first()} ?"}
              phx-debounce="300"
            >{@form[:body].value}</textarea>

            <!-- Image previews -->
            <div :if={@uploads.images.entries != []} class="grid grid-cols-3 gap-2">
              <div :for={entry <- @uploads.images.entries} class="relative group aspect-square">
                <.live_img_preview entry={entry} class="w-full h-full object-cover rounded-lg" />
                <div :if={entry.progress > 0 and entry.progress < 100} class="absolute bottom-0 left-0 right-0 h-1 bg-base-300 rounded-b-lg overflow-hidden">
                  <div class="h-full bg-primary transition-all" style={"width: #{entry.progress}%"}></div>
                </div>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="absolute top-1 right-1 btn btn-circle btn-xs bg-black/50 border-0 hover:bg-black/70"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
                <div :for={err <- upload_errors(@uploads.images, entry)} class="absolute bottom-1 left-1 text-error text-xs bg-base-100 px-1 rounded">
                  {upload_error_to_string(err)}
                </div>
              </div>
            </div>

            <!-- Upload errors -->
            <div :for={err <- upload_errors(@uploads.images)} class="text-error text-sm">
              {upload_error_to_string(err)}
            </div>
          </div>

          <!-- Footer toolbar -->
          <div class="p-4 border-t border-white/20 space-y-3">
            <!-- Add to post section -->
            <div class="flex items-center justify-between p-3 border border-white/20 rounded-lg">
              <span class="text-sm font-medium">Ajouter à votre publication</span>
              <div class="flex gap-1">
                <label class="btn btn-ghost btn-sm btn-circle text-success cursor-pointer" phx-drop-target={@uploads.images.ref}>
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  <.live_file_input upload={@uploads.images} class="hidden" />
                </label>
                <button type="button" class="btn btn-ghost btn-sm btn-circle text-warning">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </button>
                <button type="button" class="btn btn-ghost btn-sm btn-circle text-error">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Submit button -->
            <button type="submit" class="btn btn-primary w-full">
              Publier
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp upload_error_to_string(:too_large), do: "Max 10 Mo"
  defp upload_error_to_string(:too_many_files), do: "Max 20 images"
  defp upload_error_to_string(:not_accepted), do: "Format non accepté"
  defp upload_error_to_string(_), do: "Erreur"

  # ============== EDIT POST MODAL ==============

  attr :form, :map, required: true
  attr :uploads, :map, required: true
  attr :current_user, :map, required: true
  attr :post, :map, required: true

  def edit_post_modal(assigns) do
    ~H"""
    <!-- Overlay -->
    <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <!-- Modal -->
      <div
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-lg max-h-[90vh] flex flex-col"
        phx-click-away="close_edit_modal"
      >
        <!-- Header -->
        <div class="flex items-center justify-between p-4 border-b border-white/20">
          <div></div>
          <h3 class="text-xl font-bold">Modifier la publication</h3>
          <button
            type="button"
            phx-click="close_edit_modal"
            class="btn btn-ghost btn-sm btn-circle"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Body -->
        <.form for={@form} phx-submit="update_post" phx-change="validate_edit" class="flex flex-col flex-1 overflow-hidden">
          <input type="hidden" name="post[id]" value={@post.id} />
          <div class="p-4 flex-1 overflow-y-auto space-y-4">
            <!-- User info + visibility -->
            <div class="flex items-center gap-3">
              <.user_avatar name={@current_user.name} avatar={@current_user.avatar} />
              <div>
                <div class="font-semibold">{@current_user.name}</div>
                <!-- Visibility dropdown -->
                <div class="dropdown dropdown-bottom">
                  <div tabindex="0" role="button" class="btn btn-xs btn-ghost gap-1 -ml-2">
                    <.visibility_icon visibility={@form[:visibility].value || "public"} />
                    <span class="text-xs">{visibility_label(@form[:visibility].value || "public")}</span>
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                  <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[60] w-52 p-2 shadow-lg border border-white/20">
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="post[visibility]" value="public" checked={(@form[:visibility].value || "public") == "public"} class="radio radio-sm" />
                        <.visibility_icon visibility="public" />
                        <div>
                          <div class="font-medium text-sm">Public</div>
                          <div class="text-xs text-base-content/50">Tout le monde</div>
                        </div>
                      </label>
                    </li>
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="post[visibility]" value="friends" checked={@form[:visibility].value == "friends"} class="radio radio-sm" />
                        <.visibility_icon visibility="friends" />
                        <div>
                          <div class="font-medium text-sm">Amis</div>
                          <div class="text-xs text-base-content/50">Vos amis uniquement</div>
                        </div>
                      </label>
                    </li>
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="post[visibility]" value="private" checked={@form[:visibility].value == "private"} class="radio radio-sm" />
                        <.visibility_icon visibility="private" />
                        <div>
                          <div class="font-medium text-sm">Moi uniquement</div>
                          <div class="text-xs text-base-content/50">Privé</div>
                        </div>
                      </label>
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <!-- Title input -->
            <div>
              <input
                type="text"
                name="post[title]"
                value={@form[:title].value}
                class="input input-ghost w-full text-lg font-medium focus:outline-none px-0"
                placeholder="Titre de votre publication..."
                phx-debounce="300"
              />
              <.field_error field={@form[:title]} />
            </div>

            <!-- Body textarea -->
            <textarea
              name="post[body]"
              class="textarea textarea-ghost w-full min-h-[100px] text-base resize-none focus:outline-none px-0"
              placeholder={"Quoi de neuf, #{@current_user.name |> String.split() |> List.first()} ?"}
              phx-debounce="300"
            >{@form[:body].value}</textarea>

            <!-- Existing images -->
            <div :if={@post.images != []} class="space-y-2">
              <div class="text-sm font-medium text-base-content/70">Images existantes</div>
              <div class="grid grid-cols-4 gap-2">
                <div :for={image <- @post.images} class="relative group aspect-square">
                  <img
                    src={"/uploads/posts/#{image.filename}"}
                    alt="Image du post"
                    class="w-full h-full object-cover rounded-lg"
                  />
                  <button
                    type="button"
                    phx-click="delete_image"
                    phx-value-id={image.id}
                    data-confirm="Supprimer cette image ?"
                    class="absolute top-1 right-1 btn btn-circle btn-xs bg-error border-0 hover:bg-error/80 opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>

            <!-- New image previews -->
            <div :if={@uploads.images.entries != []} class="space-y-2">
              <div class="text-sm font-medium text-base-content/70">Nouvelles images</div>
              <div class="grid grid-cols-4 gap-2">
                <div :for={entry <- @uploads.images.entries} class="relative group aspect-square">
                  <.live_img_preview entry={entry} class="w-full h-full object-cover rounded-lg" />
                  <div :if={entry.progress > 0 and entry.progress < 100} class="absolute bottom-0 left-0 right-0 h-1 bg-base-300 rounded-b-lg overflow-hidden">
                    <div class="h-full bg-primary transition-all" style={"width: #{entry.progress}%"}></div>
                  </div>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="absolute top-1 right-1 btn btn-circle btn-xs bg-black/50 border-0 hover:bg-black/70"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                  <div :for={err <- upload_errors(@uploads.images, entry)} class="absolute bottom-1 left-1 text-error text-xs bg-base-100 px-1 rounded">
                    {upload_error_to_string(err)}
                  </div>
                </div>
              </div>
            </div>

            <!-- Upload errors -->
            <div :for={err <- upload_errors(@uploads.images)} class="text-error text-sm">
              {upload_error_to_string(err)}
            </div>
          </div>

          <!-- Footer toolbar -->
          <div class="p-4 border-t border-white/20 space-y-3">
            <!-- Add to post section -->
            <div class="flex items-center justify-between p-3 border border-white/20 rounded-lg">
              <span class="text-sm font-medium">Ajouter des images</span>
              <div class="flex gap-1">
                <label class="btn btn-ghost btn-sm btn-circle text-success cursor-pointer" phx-drop-target={@uploads.images.ref}>
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  <.live_file_input upload={@uploads.images} class="hidden" />
                </label>
              </div>
            </div>

            <!-- Submit button -->
            <button type="submit" class="btn btn-primary w-full">
              Enregistrer les modifications
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  # ============== REACTIONS MODAL ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true
  attr :reactions, :list, required: true
  attr :filter, :string, default: "all"
  attr :friendship_statuses, :map, default: %{}

  def reactions_modal(assigns) do
    # Compter les réactions par type
    counts = Enum.reduce(assigns.reactions, %{}, fn r, acc ->
      Map.update(acc, r.type, 1, &(&1 + 1))
    end)

    # Filtrer les réactions selon le filtre actif
    filtered_reactions = if assigns.filter == "all" do
      assigns.reactions
    else
      Enum.filter(assigns.reactions, fn r -> r.type == assigns.filter end)
    end

    assigns = assigns
      |> assign(:counts, counts)
      |> assign(:filtered_reactions, filtered_reactions)
      |> assign(:total, length(assigns.reactions))

    ~H"""
    <!-- Overlay -->
    <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <!-- Modal -->
      <div
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md max-h-[80vh] flex flex-col"
        phx-click-away="close_reactions"
      >
        <!-- Header avec tabs -->
        <div class="border-b border-white/20">
          <div class="flex items-center justify-between p-3 border-b border-white/20">
            <h3 class="text-lg font-semibold">Réactions</h3>
            <button
              type="button"
              phx-click="close_reactions"
              class="btn btn-ghost btn-sm btn-circle"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Tabs de filtrage -->
          <div class="flex overflow-x-auto px-2 py-2 gap-1">
            <button
              type="button"
              phx-click="filter_reactions"
              phx-value-filter="all"
              class={"btn btn-sm #{if @filter == "all", do: "btn-primary", else: "btn-ghost"}"}
            >
              Tous {@total}
            </button>
            <button
              :for={{type, count} <- Enum.sort_by(@counts, fn {_, c} -> c end, :desc)}
              type="button"
              phx-click="filter_reactions"
              phx-value-filter={type}
              class={"btn btn-sm gap-1 #{if @filter == type, do: "btn-primary", else: "btn-ghost"}"}
            >
              <span class="text-base">{reaction_emoji(type)}</span>
              <span>{count}</span>
            </button>
          </div>
        </div>

        <!-- Liste des utilisateurs -->
        <div class="flex-1 overflow-y-auto">
          <div class="divide-y divide-white/15">
            <.reaction_user_item
              :for={reaction <- @filtered_reactions}
              reaction={reaction}
              current_user={@current_user}
              friendship_status={Map.get(@friendship_statuses, reaction.user_id, :none)}
            />
          </div>

          <div :if={@filtered_reactions == []} class="text-center text-base-content/50 py-8">
            Aucune réaction
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ============== COMMENT REACTIONS MODAL ==============

  attr :comment, :map, required: true
  attr :current_user, :map, required: true
  attr :reactions, :list, required: true
  attr :filter, :string, default: "all"
  attr :friendship_statuses, :map, default: %{}

  def comment_reactions_modal(assigns) do
    # Compter les réactions par type
    counts = Enum.reduce(assigns.reactions, %{}, fn r, acc ->
      Map.update(acc, r.type, 1, &(&1 + 1))
    end)

    # Filtrer les réactions selon le filtre actif
    filtered_reactions = if assigns.filter == "all" do
      assigns.reactions
    else
      Enum.filter(assigns.reactions, fn r -> r.type == assigns.filter end)
    end

    assigns = assigns
      |> assign(:counts, counts)
      |> assign(:filtered_reactions, filtered_reactions)
      |> assign(:total, length(assigns.reactions))

    ~H"""
    <!-- Overlay -->
    <div class="fixed inset-0 bg-black/50 z-[60] flex items-center justify-center p-4">
      <!-- Modal -->
      <div
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-sm max-h-[70vh] flex flex-col"
        phx-click-away="close_comment_reactions"
      >
        <!-- Header avec tabs -->
        <div class="border-b border-white/20">
          <div class="flex items-center justify-between p-3 border-b border-white/20">
            <h3 class="text-base font-semibold">Réactions au commentaire</h3>
            <button
              type="button"
              phx-click="close_comment_reactions"
              class="btn btn-ghost btn-sm btn-circle"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Tabs de filtrage -->
          <div class="flex overflow-x-auto px-2 py-2 gap-1">
            <button
              type="button"
              phx-click="filter_comment_reactions"
              phx-value-filter="all"
              class={"btn btn-xs #{if @filter == "all", do: "btn-primary", else: "btn-ghost"}"}
            >
              Tous {@total}
            </button>
            <button
              :for={{type, count} <- Enum.sort_by(@counts, fn {_, c} -> c end, :desc)}
              type="button"
              phx-click="filter_comment_reactions"
              phx-value-filter={type}
              class={"btn btn-xs gap-1 #{if @filter == type, do: "btn-primary", else: "btn-ghost"}"}
            >
              <span class="text-sm">{reaction_emoji(type)}</span>
              <span>{count}</span>
            </button>
          </div>
        </div>

        <!-- Liste des utilisateurs -->
        <div class="flex-1 overflow-y-auto">
          <div class="divide-y divide-white/15">
            <.comment_reaction_user_item
              :for={reaction <- @filtered_reactions}
              reaction={reaction}
              current_user={@current_user}
              friendship_status={Map.get(@friendship_statuses, reaction.user_id, :none)}
            />
          </div>

          <div :if={@filtered_reactions == []} class="text-center text-base-content/50 py-6 text-sm">
            Aucune réaction
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ============== COMMENT REACTION USER ITEM ==============

  attr :reaction, :map, required: true
  attr :current_user, :map, required: true
  attr :friendship_status, :atom, required: true

  defp comment_reaction_user_item(assigns) do
    ~H"""
    <div class="flex items-center gap-3 p-3 hover:bg-base-200/50">
      <!-- Avatar avec emoji réaction -->
      <div class="relative">
        <.user_avatar name={@reaction.user.name} avatar={@reaction.user.avatar} size="w-8 h-8" />
        <span class="absolute -bottom-1 -right-1 text-xs bg-base-100 rounded-full">
          {reaction_emoji(@reaction.type)}
        </span>
      </div>

      <!-- Nom de l'utilisateur -->
      <div class="flex-1 min-w-0">
        <div class="font-medium text-sm truncate">{@reaction.user.name}</div>
      </div>

      <!-- Bouton d'action -->
      <div :if={@reaction.user_id != @current_user.id}>
        <%= case @friendship_status do %>
          <% :friends -> %>
            <span class="badge badge-success badge-sm gap-1">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
              Ami
            </span>
          <% :request_sent -> %>
            <span class="badge badge-ghost badge-sm">En attente</span>
          <% :request_received -> %>
            <button
              type="button"
              phx-click="accept_friend_from_comment_reactions"
              phx-value-user-id={@reaction.user_id}
              class="btn btn-xs btn-primary"
            >
              Accepter
            </button>
          <% _ -> %>
            <button
              type="button"
              phx-click="send_friend_request_from_comment_reactions"
              phx-value-user-id={@reaction.user_id}
              class="btn btn-xs btn-outline btn-primary"
            >
              Ajouter
            </button>
        <% end %>
      </div>
    </div>
    """
  end

  # ============== REACTION USER ITEM ==============

  attr :reaction, :map, required: true
  attr :current_user, :map, required: true
  attr :friendship_status, :atom, required: true

  defp reaction_user_item(assigns) do
    ~H"""
    <div class="flex items-center gap-3 p-3 hover:bg-base-200/50">
      <!-- Avatar avec emoji réaction -->
      <div class="relative">
        <.user_avatar name={@reaction.user.name} avatar={@reaction.user.avatar} />
        <span class="absolute -bottom-1 -right-1 text-sm bg-base-100 rounded-full">
          {reaction_emoji(@reaction.type)}
        </span>
      </div>

      <!-- Nom de l'utilisateur -->
      <div class="flex-1 min-w-0">
        <div class="font-medium truncate">{@reaction.user.name}</div>
        <div class="text-xs text-base-content/50">{@reaction.user.email}</div>
      </div>

      <!-- Bouton d'action (Add friend / En attente / Amis) -->
      <div :if={@reaction.user_id != @current_user.id}>
        <%= case @friendship_status do %>
          <% :friends -> %>
            <span class="btn btn-sm btn-ghost gap-1 pointer-events-none">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
              Amis
            </span>
          <% :request_sent -> %>
            <button
              type="button"
              phx-click="cancel_friend_request_from_reactions"
              phx-value-user-id={@reaction.user_id}
              class="btn btn-sm btn-ghost"
            >
              En attente
            </button>
          <% :request_received -> %>
            <button
              type="button"
              phx-click="accept_friend_from_reactions"
              phx-value-user-id={@reaction.user_id}
              class="btn btn-sm btn-primary"
            >
              Accepter
            </button>
          <% _ -> %>
            <button
              type="button"
              phx-click="send_friend_request_from_reactions"
              phx-value-user-id={@reaction.user_id}
              class="btn btn-sm btn-outline btn-primary gap-1"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
              </svg>
              Ajouter
            </button>
        <% end %>
      </div>
    </div>
    """
  end

  # ============== POST DETAIL MODAL (with comments) ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true
  attr :comment_form, :map, required: true
  attr :comment_form_id, :any, required: true
  attr :replying_to, :map, default: nil
  attr :uploads, :map, required: true

  def post_detail_modal(assigns) do
    # Préparer les données de réactions
    reactions = Map.get(assigns.post, :reactions, [])
    counts = Enum.reduce(reactions, %{}, fn r, acc ->
      Map.update(acc, r.type, 1, &(&1 + 1))
    end)
    user_reaction = Enum.find(reactions, fn r -> r.user_id == assigns.current_user.id end)
    reactions_data = %{counts: counts, total: length(reactions), user_reaction: user_reaction}
    comment_count = length(assigns.post.comments || [])

    assigns = assigns
      |> assign(:reactions_data, reactions_data)
      |> assign(:comment_count, comment_count)

    ~H"""
    <!-- Overlay -->
    <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <!-- Modal -->
      <div
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col"
        phx-click-away="close_comments"
      >
        <!-- Header -->
        <div class="flex items-center justify-between p-4 border-b border-white/20">
          <div></div>
          <h3 class="text-xl font-bold">Publication de {@post.user.name}</h3>
          <button
            type="button"
            phx-click="close_comments"
            class="btn btn-ghost btn-sm btn-circle"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Post content -->
        <div class="flex-1 overflow-y-auto">
          <div class="p-4 border-b border-white/20">
            <!-- Post header -->
            <div class="flex items-start gap-3">
              <.profile_link user_id={@post.user_id}>
                <.user_avatar name={@post.user.name} avatar={@post.user.avatar} />
              </.profile_link>
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <.profile_link user_id={@post.user_id}>
                    <span class="font-semibold hover:underline cursor-pointer">{@post.user.name}</span>
                  </.profile_link>
                  <.visibility_badge visibility={@post.visibility} />
                </div>
                <span class="text-sm text-base-content/50" title={Calendar.strftime(@post.inserted_at, "%d %b %Y à %H:%M")}>
                  {time_ago(@post.inserted_at)}
                </span>
              </div>
            </div>

            <!-- Post body -->
            <div class="mt-3">
              <h3 :if={@post.title} class="font-semibold text-lg">{@post.title}</h3>
              <p :if={@post.body} class="text-base-content/80 mt-1">{@post.body}</p>
              <.post_images images={@post.images} post_id={@post.id} in_modal={true} />
            </div>

            <!-- Stats row -->
            <div :if={@reactions_data.total > 0 || @comment_count > 0} class="mt-3 flex items-center justify-between text-[13px] text-base-content/60">
              <button
                :if={@reactions_data.total > 0}
                type="button"
                phx-click="open_reactions"
                phx-value-id={@post.id}
                class="flex items-center gap-1.5 hover:underline"
              >
                <div class="flex">
                  <span :for={type <- top_reaction_types(@reactions_data.counts)} class="text-[15px]">
                    {reaction_emoji(type)}
                  </span>
                </div>
                <span>{@reactions_data.total}</span>
              </button>
              <div :if={@reactions_data.total == 0}></div>
              <span :if={@comment_count > 0}>{@comment_count} comment{if @comment_count > 1, do: "s", else: ""}</span>
              <div :if={@comment_count == 0}></div>
            </div>

            <!-- Action buttons -->
            <div class="mt-2">
              <.post_actions post={@post} current_user={@current_user} reactions_data={@reactions_data} show_comment_button={false} />
            </div>
          </div>

          <!-- Comments section -->
          <div class="p-4">
            <div class="text-sm font-semibold text-base-content/70 mb-4">
              {length(@post.comments)} commentaire{if length(@post.comments) > 1, do: "s", else: ""}
            </div>

            <!-- Comments list -->
            <div class="space-y-5">
              <.comment_item
                :for={comment <- @post.comments}
                comment={comment}
                current_user={@current_user}
                post={@post}
                replying_to={@replying_to}
                comment_form={@comment_form}
                comment_form_id={@comment_form_id}
              />
            </div>

            <!-- Empty state -->
            <div :if={@post.comments == []} class="text-center text-base-content/50 py-8">
              Aucun commentaire. Soyez le premier à commenter !
            </div>
          </div>
        </div>

        <!-- Comment input -->
        <div class="p-4 border-t border-white/20 bg-base-100">
          <!-- Replying indicator -->
          <div :if={@replying_to} class="mb-3 flex items-center gap-2 text-sm bg-base-200 rounded-lg px-3 py-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
            </svg>
            <span class="flex-1 text-base-content/70">
              Répondre à <strong class="text-base-content">{@replying_to.user.name}</strong>
            </span>
            <button type="button" phx-click="cancel_reply" class="btn btn-ghost btn-xs btn-circle hover:bg-base-300">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Image preview -->
          <div :if={@uploads.comment_images.entries != []} class="mb-3 flex gap-2">
            <div :for={entry <- @uploads.comment_images.entries} class="relative">
              <.live_img_preview entry={entry} class="w-20 h-20 object-cover rounded-lg" />
              <button
                type="button"
                phx-click="cancel-comment-upload"
                phx-value-ref={entry.ref}
                class="absolute -top-2 -right-2 btn btn-circle btn-xs bg-base-300 hover:bg-error hover:text-white border-0"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
              <div :if={entry.progress > 0 and entry.progress < 100} class="absolute bottom-0 left-0 right-0 h-1 bg-base-300 rounded-b-lg overflow-hidden">
                <div class="h-full bg-primary transition-all" style={"width: #{entry.progress}%"}></div>
              </div>
            </div>
          </div>

          <.form for={@comment_form} phx-submit={if @replying_to, do: "add_reply", else: "add_comment"} phx-change="validate_comment" id={"comment-form-#{@comment_form_id}"} class="flex items-start gap-3">
            <input type="hidden" name="comment[post_id]" value={@post.id} />
            <input :if={@replying_to} type="hidden" name="comment[parent_id]" value={@replying_to.id} />
            <.user_avatar name={@current_user.name} avatar={@current_user.avatar} size="w-9 h-9" />
            <div class="flex-1">
              <div class="relative flex items-center bg-base-200 rounded-2xl">
                <input
                  type="text"
                  name="comment[body]"
                  class="flex-1 bg-transparent px-4 py-2.5 text-sm focus:outline-none placeholder:text-base-content/50"
                  placeholder={if @replying_to, do: "Écrire une réponse...", else: "Écrire un commentaire..."}
                  autocomplete="off"
                />
                <div class="flex items-center gap-1 pr-2">
                  <!-- Photo button -->
                  <label class="btn btn-ghost btn-circle btn-sm text-base-content/50 hover:text-success cursor-pointer">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <.live_file_input upload={@uploads.comment_images} class="hidden" />
                  </label>
                  <!-- Send button -->
                  <button
                    type="submit"
                    class="btn btn-ghost btn-circle btn-sm text-primary hover:bg-primary/10"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                      <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  # ============== SHARE POST MODAL ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true
  attr :form, :map, required: true

  def share_post_modal(assigns) do
    ~H"""
    <!-- Overlay -->
    <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <!-- Modal -->
      <div
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-lg max-h-[90vh] flex flex-col"
        phx-click-away="close_share_modal"
      >
        <!-- Header -->
        <div class="flex items-center justify-between p-4 border-b border-base-200">
          <div></div>
          <h3 class="text-xl font-bold">Partager la publication</h3>
          <button
            type="button"
            phx-click="close_share_modal"
            class="btn btn-ghost btn-sm btn-circle"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Body -->
        <.form for={@form} phx-submit="share_post" phx-change="validate_share" class="flex flex-col flex-1 overflow-hidden">
          <input type="hidden" name="share[shared_post_id]" value={@post.id} />

          <div class="p-4 flex-1 overflow-y-auto space-y-4">
            <!-- User info + visibility -->
            <div class="flex items-center gap-3">
              <.user_avatar name={@current_user.name} avatar={@current_user.avatar} />
              <div>
                <div class="font-semibold">{@current_user.name}</div>
                <!-- Visibility dropdown -->
                <div class="dropdown dropdown-bottom">
                  <div tabindex="0" role="button" class="btn btn-xs btn-ghost gap-1 -ml-2">
                    <.visibility_icon visibility={@form[:visibility].value || "public"} />
                    <span class="text-xs">{visibility_label(@form[:visibility].value || "public")}</span>
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                  <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[60] w-52 p-2 shadow-lg border border-base-200">
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="share[visibility]" value="public" checked={(@form[:visibility].value || "public") == "public"} class="radio radio-sm" />
                        <.visibility_icon visibility="public" />
                        <div>
                          <div class="font-medium text-sm">Public</div>
                          <div class="text-xs text-base-content/50">Tout le monde</div>
                        </div>
                      </label>
                    </li>
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="share[visibility]" value="friends" checked={@form[:visibility].value == "friends"} class="radio radio-sm" />
                        <.visibility_icon visibility="friends" />
                        <div>
                          <div class="font-medium text-sm">Amis</div>
                          <div class="text-xs text-base-content/50">Vos amis uniquement</div>
                        </div>
                      </label>
                    </li>
                    <li>
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input type="radio" name="share[visibility]" value="private" checked={@form[:visibility].value == "private"} class="radio radio-sm" />
                        <.visibility_icon visibility="private" />
                        <div>
                          <div class="font-medium text-sm">Moi uniquement</div>
                          <div class="text-xs text-base-content/50">Privé</div>
                        </div>
                      </label>
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <!-- Optional title -->
            <input
              type="text"
              name="share[title]"
              value={@form[:title].value}
              class="input input-ghost w-full text-lg font-medium focus:outline-none px-0"
              placeholder="Ajouter un titre (optionnel)..."
              phx-debounce="300"
            />

            <!-- Optional body/comment -->
            <textarea
              name="share[body]"
              class="textarea textarea-ghost w-full min-h-[60px] text-base resize-none focus:outline-none px-0"
              placeholder="Dites quelque chose sur cette publication..."
              phx-debounce="300"
            >{@form[:body].value}</textarea>

            <!-- Preview of shared post -->
            <div class="border border-base-300 rounded-lg overflow-hidden bg-base-200/50">
              <div class="p-3">
                <div class="flex items-center gap-2.5">
                  <.user_avatar name={@post.user.name} avatar={@post.user.avatar} size="w-8 h-8" />
                  <div>
                    <span class="font-semibold text-sm">{@post.user.name}</span>
                    <div class="text-xs text-base-content/50">{time_ago(@post.inserted_at)}</div>
                  </div>
                </div>
                <div :if={@post.title || @post.body} class="mt-2">
                  <p :if={@post.title} class="font-medium text-sm">{@post.title}</p>
                  <p :if={@post.body} class="text-sm text-base-content/80 line-clamp-3">{@post.body}</p>
                </div>
              </div>
              <!-- First image preview if any -->
              <img
                :if={@post.images != []}
                src={"/uploads/posts/#{List.first(@post.images).filename}"}
                alt="Image du post"
                class="w-full max-h-[200px] object-cover"
              />
            </div>
          </div>

          <!-- Footer -->
          <div class="p-4 border-t border-base-200">
            <button type="submit" class="btn btn-primary w-full gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
              </svg>
              Partager maintenant
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  # ============== COMMENT ITEM ==============

  attr :comment, :map, required: true
  attr :current_user, :map, required: true
  attr :post, :map, required: true
  attr :replying_to, :map, default: nil
  attr :comment_form, :map, default: nil
  attr :comment_form_id, :any, default: nil
  attr :is_reply, :boolean, default: false

  defp comment_item(assigns) do
    replies = case Map.get(assigns.comment, :replies) do
      %Ecto.Association.NotLoaded{} -> []
      nil -> []
      loaded_replies -> loaded_replies
    end

    reactions = case Map.get(assigns.comment, :reactions) do
      %Ecto.Association.NotLoaded{} -> []
      nil -> []
      loaded_reactions -> loaded_reactions
    end

    images = case Map.get(assigns.comment, :images) do
      %Ecto.Association.NotLoaded{} -> []
      nil -> []
      loaded_images -> loaded_images
    end

    # Calculer les données de réaction
    reaction_counts = Enum.reduce(reactions, %{}, fn r, acc ->
      Map.update(acc, r.type, 1, &(&1 + 1))
    end)
    user_reaction = Enum.find(reactions, fn r -> r.user_id == assigns.current_user.id end)

    assigns = assigns
      |> assign(:replies, replies)
      |> assign(:reactions, reactions)
      |> assign(:images, images)
      |> assign(:reaction_counts, reaction_counts)
      |> assign(:reaction_total, length(reactions))
      |> assign(:user_reaction, user_reaction)

    ~H"""
    <div class="flex gap-3 items-start">
      <.profile_link user_id={@comment.user_id}>
        <.user_avatar name={@comment.user.name} avatar={@comment.user.avatar} size={if @is_reply, do: "w-6 h-6", else: "w-8 h-8"} />
      </.profile_link>
      <div class="flex-1 min-w-0">
        <!-- Bulle du commentaire -->
        <div class="inline-block max-w-[85%]">
          <div :if={@comment.body && @comment.body != ""} class="bg-base-200 rounded-2xl px-4 py-2">
            <.profile_link user_id={@comment.user_id}>
              <span class="font-semibold text-sm block hover:underline cursor-pointer">{@comment.user.name}</span>
            </.profile_link>
            <p class="text-sm whitespace-pre-wrap break-words">{@comment.body}</p>
          </div>
          <!-- Nom si pas de texte mais image -->
          <.profile_link user_id={@comment.user_id}>
            <span :if={(!@comment.body || @comment.body == "") && @images != []} class="font-semibold text-sm block mb-1 hover:underline cursor-pointer">{@comment.user.name}</span>
          </.profile_link>
          <!-- Images du commentaire -->
          <div :if={@images != []} class="mt-1 flex flex-wrap gap-1">
            <img
              :for={image <- @images}
              src={"/uploads/comments/#{image.filename}"}
              alt="Image du commentaire"
              class="rounded-lg max-w-xs max-h-48 object-cover cursor-pointer hover:opacity-90 transition-opacity"
              phx-click="open_image_preview"
              phx-value-src={"/uploads/comments/#{image.filename}"}
            />
          </div>
        </div>

        <!-- Actions et réactions -->
        <div class={"flex items-center flex-wrap gap-x-1 mt-2 ml-3 text-xs #{if @reaction_total > 0, do: "gap-y-1", else: ""}"}>
          <span class="text-base-content/50">{time_ago(@comment.inserted_at)}</span>
          <span class="text-base-content/30">·</span>
          <!-- Bouton J'aime avec picker -->
          <div class="dropdown dropdown-top dropdown-hover">
            <span
              tabindex="0"
              role="button"
              class={"font-semibold hover:underline cursor-pointer #{if @user_reaction, do: "text-primary", else: "text-base-content/60 hover:text-base-content"}"}
            >
              {if @user_reaction, do: reaction_label(@user_reaction.type), else: "J'aime"}
            </span>
            <div class="dropdown-content pb-2 z-50">
              <div class="bg-base-100 rounded-full shadow-lg border border-white/20 p-1 flex gap-1">
                <button
                  :for={type <- reaction_types()}
                  type="button"
                  phx-click="toggle_comment_reaction"
                  phx-value-comment-id={@comment.id}
                  phx-value-type={type}
                  onclick="this.closest('.dropdown').querySelector('[tabindex]').blur()"
                  class={"btn btn-ghost btn-circle btn-sm hover:scale-125 transition-transform #{if @user_reaction && @user_reaction.type == type, do: "bg-primary/20", else: ""}"}
                  title={reaction_label(type)}
                >
                  <span class="text-lg">{reaction_emoji(type)}</span>
                </button>
              </div>
            </div>
          </div>
          <span :if={!@is_reply} class="text-base-content/30">·</span>
          <span
            :if={!@is_reply}
            phx-click="start_reply"
            phx-value-id={@comment.id}
            class="font-semibold text-base-content/60 hover:text-base-content hover:underline cursor-pointer"
          >
            Répondre
          </span>
          <span :if={@comment.user_id == @current_user.id or @post.user_id == @current_user.id} class="text-base-content/30">·</span>
          <span
            :if={@comment.user_id == @current_user.id or @post.user_id == @current_user.id}
            phx-click="delete_comment"
            phx-value-id={@comment.id}
            class="text-error/70 hover:text-error hover:underline cursor-pointer"
          >
            Supprimer
          </span>
          <!-- Badge de réactions inline (cliquable) -->
          <button
            :if={@reaction_total > 0}
            type="button"
            phx-click="open_comment_reactions"
            phx-value-comment-id={@comment.id}
            class="ml-auto flex items-center gap-1 bg-base-200 hover:bg-base-300 rounded-full px-2 py-0.5 cursor-pointer transition-colors"
          >
            <.comment_reaction_summary counts={@reaction_counts} />
            <span class="text-base-content/60">{@reaction_total}</span>
          </button>
        </div>

        <!-- Replies section -->
        <div :if={@replies != []} class="mt-4 ml-4 space-y-4 border-l-2 border-white/20 pl-4">
          <.comment_item
            :for={reply <- @replies}
            comment={reply}
            current_user={@current_user}
            post={@post}
            is_reply={true}
          />
        </div>
      </div>
    </div>
    """
  end

  # ============== VISIBILITY ICON ==============

  attr :visibility, :string, required: true

  def visibility_icon(%{visibility: "public"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    """
  end

  def visibility_icon(%{visibility: "friends"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
    """
  end

  def visibility_icon(%{visibility: "private"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
    </svg>
    """
  end

  def visibility_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    """
  end

  defp visibility_label("public"), do: "Public"
  defp visibility_label("friends"), do: "Amis"
  defp visibility_label("private"), do: "Moi uniquement"
  defp visibility_label(_), do: "Public"

  # ============== POST LIST ==============

  attr :posts, :list, required: true
  attr :current_user, :map, required: true
  attr :feed_filter, :string, default: "standard"
  attr :online_user_ids, :list, default: []

  def post_list(assigns) do
    ~H"""
    <div class="space-y-4 md:space-y-6">
      <!-- Header avec titre + filtres -->
      <div class="space-y-3">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <h2 class="text-lg md:text-xl font-bold text-base-content">Fil d'actualité</h2>
            <div class="flex items-center gap-1.5 px-2 py-0.5 bg-success/10 rounded-full">
              <span class="w-2 h-2 bg-success rounded-full animate-pulse"></span>
              <span class="text-success text-xs font-medium">Live</span>
            </div>
          </div>
          <span class="text-base-content/40 text-xs md:text-sm font-medium">
            {length(@posts)} publication{if length(@posts) > 1, do: "s", else: ""}
          </span>
        </div>
        <!-- Feed filter tabs -->
        <div class="flex gap-1 bg-base-200 rounded-lg p-1">
          <button
            phx-click="filter_feed"
            phx-value-filter="date"
            class={"flex-1 py-1.5 px-3 rounded-md text-sm font-medium transition-all #{if @feed_filter == "date", do: "bg-base-100 shadow-sm text-pink-500", else: "text-base-content/50 hover:text-base-content"}"}
          >
            💘 Dates
          </button>
          <button
            phx-click="filter_feed"
            phx-value-filter="standard"
            class={"flex-1 py-1.5 px-3 rounded-md text-sm font-medium transition-all #{if @feed_filter == "standard", do: "bg-base-100 shadow-sm text-base-content", else: "text-base-content/50 hover:text-base-content"}"}
          >
            Posts
          </button>
        </div>
      </div>

      <.empty_state :if={@posts == []} />

      <%= for post <- @posts do %>
        <%= if post.post_type == "date" do %>
          <.date_post_card post={post} current_user={@current_user} online_user_ids={@online_user_ids} />
        <% else %>
          <.post_item post={post} current_user={@current_user} online_user_ids={@online_user_ids} />
        <% end %>
      <% end %>
    </div>
    """
  end

  # ============== POST ITEM ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true
  attr :online_user_ids, :list, default: []

  def post_item(assigns) do
    comment_count = length(assigns.post.comments || [])
    share_count = length(Map.get(assigns.post, :shares, []))
    reactions = get_reactions_data(assigns.post, assigns.current_user)
    assigns = assigns
      |> assign(:comment_count, comment_count)
      |> assign(:share_count, share_count)
      |> assign(:reactions_data, reactions)

    ~H"""
    <article id={"post-#{@post.id}"} class="bg-base-100 rounded-lg shadow-sm">
      <!-- Header compact -->
      <div class="px-3 pt-3 pb-2">
        <.post_header post={@post} current_user={@current_user} online_user_ids={@online_user_ids} />
      </div>

      <!-- Text content (si le post a un titre ou body) -->
      <.post_text :if={@post.title || @post.body} post={@post} />

      <!-- Images du post (seulement si ce n'est pas un partage) -->
      <.post_images :if={!@post.shared_post_id && @post.images != []} images={@post.images} post_id={@post.id} />

      <!-- Shared post preview -->
      <.shared_post_preview :if={@post.shared_post} shared_post={@post.shared_post} />

      <!-- Stats + Actions -->
      <.post_footer
        post={@post}
        comment_count={@comment_count}
        share_count={@share_count}
        current_user={@current_user}
        reactions_data={@reactions_data}
      />
    </article>
    """
  end

  # ============== SHARED POST PREVIEW ==============

  attr :shared_post, :map, required: true

  defp shared_post_preview(assigns) do
    ~H"""
    <div class="mx-3 mb-2 border border-base-300 rounded-lg overflow-hidden bg-base-200/30">
      <!-- Shared post header -->
      <div class="p-3 pb-2">
        <div class="flex items-center gap-2">
          <.user_avatar name={@shared_post.user.name} avatar={@shared_post.user.avatar} size="w-8 h-8" />
          <div>
            <span class="font-semibold text-sm">{@shared_post.user.name}</span>
            <div class="text-xs text-base-content/50">{time_ago(@shared_post.inserted_at)}</div>
          </div>
        </div>
        <!-- Shared post text -->
        <div :if={@shared_post.title || @shared_post.body} class="mt-2">
          <p :if={@shared_post.title} class="font-medium text-sm">{@shared_post.title}</p>
          <p :if={@shared_post.body} class="text-sm text-base-content/80">{@shared_post.body}</p>
        </div>
      </div>
      <!-- Shared post images -->
      <div :if={@shared_post.images != []} class="bg-base-300">
        <img
          :if={length(@shared_post.images) == 1}
          src={"/uploads/posts/#{List.first(@shared_post.images).filename}"}
          alt="Image"
          class="w-full max-h-[300px] object-cover"
        />
        <div :if={length(@shared_post.images) > 1} class="grid grid-cols-2 gap-[1px]">
          <img
            :for={image <- Enum.take(@shared_post.images, 4)}
            src={"/uploads/posts/#{image.filename}"}
            alt="Image"
            class="w-full h-[120px] object-cover"
          />
        </div>
      </div>
    </div>
    """
  end

  # Helper pour préparer les données de réactions
  defp get_reactions_data(post, current_user) do
    reactions = Map.get(post, :reactions, [])

    # Compter par type
    counts = Enum.reduce(reactions, %{}, fn r, acc ->
      Map.update(acc, r.type, 1, &(&1 + 1))
    end)

    # Trouver la réaction de l'utilisateur actuel
    user_reaction = Enum.find(reactions, fn r -> r.user_id == current_user.id end)

    %{
      counts: counts,
      total: length(reactions),
      user_reaction: user_reaction
    }
  end

  # ============== POST FOOTER ==============

  attr :post, :map, required: true
  attr :comment_count, :integer, required: true
  attr :share_count, :integer, default: 0
  attr :current_user, :map, required: true
  attr :reactions_data, :map, required: true

  defp post_footer(assigns) do
    ~H"""
    <div>
      <!-- Stats row - style Facebook -->
      <div :if={@reactions_data.total > 0 || @comment_count > 0 || @share_count > 0} class="px-3 py-1.5 flex items-center justify-between text-[13px] text-base-content/60">
        <!-- Réactions à gauche -->
        <button
          :if={@reactions_data.total > 0}
          type="button"
          phx-click="open_reactions"
          phx-value-id={@post.id}
          class="flex items-center gap-1.5 hover:underline"
        >
          <div class="flex">
            <span :for={type <- top_reaction_types(@reactions_data.counts)} class="text-[15px]">
              {reaction_emoji(type)}
            </span>
          </div>
          <span>{@reactions_data.total}</span>
        </button>
        <div :if={@reactions_data.total == 0}></div>

        <!-- Commentaires et Partages à droite -->
        <div class="flex items-center gap-2">
          <button
            :if={@comment_count > 0}
            type="button"
            phx-click="open_comments"
            phx-value-id={@post.id}
            class="hover:underline"
          >
            {@comment_count} comment{if @comment_count > 1, do: "s", else: ""}
          </button>
          <span :if={@share_count > 0} class="hover:underline cursor-default">
            {@share_count} partage{if @share_count > 1, do: "s", else: ""}
          </span>
        </div>
      </div>

      <!-- Action buttons -->
      <div class="mx-3">
        <.post_actions post={@post} current_user={@current_user} reactions_data={@reactions_data} />
      </div>
    </div>
    """
  end

  # Helper pour obtenir les top types de réactions
  defp top_reaction_types(counts) do
    counts
    |> Enum.sort_by(fn {_type, count} -> count end, :desc)
    |> Enum.take(3)
    |> Enum.map(fn {type, _count} -> type end)
  end

  # ============== POST ACTIONS (Reusable Component) ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true
  attr :reactions_data, :map, required: true
  attr :show_comment_button, :boolean, default: true

  def post_actions(assigns) do
    ~H"""
    <div class="border-t border-base-200 py-1 flex">
      <!-- Like button avec picker -->
      <div class="dropdown dropdown-top dropdown-hover flex-1">
        <button
          tabindex="0"
          type="button"
          class={"flex-1 w-full py-2 rounded-md flex items-center justify-center gap-1.5 text-[13px] font-semibold transition-colors " <>
            if @reactions_data.user_reaction do
              "text-primary hover:bg-primary/5"
            else
              "text-base-content/60 hover:bg-base-200"
            end}
        >
          <span :if={@reactions_data.user_reaction} class="text-base">
            {reaction_emoji(@reactions_data.user_reaction.type)}
          </span>
          <svg :if={!@reactions_data.user_reaction} xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
          </svg>
          <span>{if @reactions_data.user_reaction, do: reaction_label(@reactions_data.user_reaction.type), else: "J'aime"}</span>
        </button>
        <!-- Reaction picker -->
        <div class="dropdown-content pb-2 z-50">
          <div class="bg-base-100 rounded-full shadow-xl border border-base-300 p-1 flex gap-0.5">
            <button
              :for={type <- reaction_types()}
              type="button"
              phx-click="toggle_reaction"
              phx-value-post-id={@post.id}
              phx-value-type={type}
              onclick="this.closest('.dropdown').querySelector('[tabindex]').blur()"
              class={"w-9 h-9 rounded-full flex items-center justify-center hover:scale-125 active:scale-110 transition-transform " <>
                if @reactions_data.user_reaction && @reactions_data.user_reaction.type == type, do: "bg-primary/20 scale-110", else: ""}
              title={reaction_label(type)}
            >
              <span class="text-2xl">{reaction_emoji(type)}</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Comment button -->
      <button
        :if={@show_comment_button}
        type="button"
        phx-click="open_comments"
        phx-value-id={@post.id}
        class="flex-1 py-2 rounded-md flex items-center justify-center gap-1.5 text-[13px] font-semibold text-base-content/60 hover:bg-base-200 transition-colors"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
        <span>Commenter</span>
      </button>

      <!-- Share button -->
      <button
        type="button"
        phx-click="open_share_modal"
        phx-value-id={if @post.shared_post_id, do: @post.shared_post_id, else: @post.id}
        class="flex-1 py-2 rounded-md flex items-center justify-center gap-1.5 text-[13px] font-semibold text-base-content/60 hover:bg-base-200 transition-colors"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
        </svg>
        <span>Partager</span>
      </button>
    </div>
    """
  end

  # ============== REACTION HELPERS ==============

  attr :counts, :map, required: true

  defp comment_reaction_summary(assigns) do
    # Trier les réactions par nombre (desc) et prendre les 2 premières
    top_reactions = assigns.counts
      |> Enum.sort_by(fn {_type, count} -> count end, :desc)
      |> Enum.take(2)
      |> Enum.map(fn {type, _count} -> type end)

    assigns = assign(assigns, :top_reactions, top_reactions)

    ~H"""
    <div class="flex -space-x-0.5">
      <span :for={type <- @top_reactions} class="text-xs">{reaction_emoji(type)}</span>
    </div>
    """
  end

  defp reaction_types, do: ["like", "love", "haha", "wow", "sad", "angry"]

  defp reaction_emoji("like"), do: "👍"
  defp reaction_emoji("love"), do: "❤️"
  defp reaction_emoji("haha"), do: "😂"
  defp reaction_emoji("wow"), do: "😮"
  defp reaction_emoji("sad"), do: "😢"
  defp reaction_emoji("angry"), do: "😠"
  defp reaction_emoji(_), do: "👍"

  defp reaction_label("like"), do: "J'aime"
  defp reaction_label("love"), do: "J'adore"
  defp reaction_label("haha"), do: "Haha"
  defp reaction_label("wow"), do: "Wow"
  defp reaction_label("sad"), do: "Triste"
  defp reaction_label("angry"), do: "Grrr"
  defp reaction_label(_), do: "J'aime"

  # ============== POST HEADER ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true
  attr :online_user_ids, :list, default: []

  defp post_header(assigns) do
    ~H"""
    <div class="flex items-center gap-2.5">
      <.profile_link user_id={@post.user_id}>
        <.user_avatar name={@post.user.name} avatar={@post.user.avatar} size="w-9 h-9" online={@post.user_id in @online_user_ids} />
      </.profile_link>

      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-1.5 flex-wrap">
          <.profile_link user_id={@post.user_id}>
            <span class="font-semibold text-[15px] text-base-content hover:underline cursor-pointer">
              {@post.user.name}
            </span>
          </.profile_link>
          <span :if={@post.shared_post_id} class="text-[13px] text-base-content/60">
            a partagé une publication
          </span>
        </div>
        <div class="flex items-center gap-1 text-[13px] text-base-content/50">
          <span>{time_ago(@post.inserted_at)}</span>
          <span>·</span>
          <.visibility_icon_small visibility={@post.visibility} />
        </div>
      </div>

      <.post_menu post={@post} current_user={@current_user} />
    </div>
    """
  end

  # Petite icône de visibilité style Facebook
  defp visibility_icon_small(%{visibility: "public"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="currentColor" viewBox="0 0 16 16">
      <path d="M8 0a8 8 0 1 0 0 16A8 8 0 0 0 8 0ZM2.04 4.326c.325 1.329 2.532 2.54 3.717 3.19.48.263.793.434.743.484-.08.08-.162.158-.242.234-.416.396-.787.749-.758 1.266.035.634.618.824 1.214 1.017.577.188 1.168.38 1.286.983.082.417-.075.988-.22 1.52-.215.782-.406 1.48.22 1.48 1.5-.5 3.798-3.186 4-5 .138-1.243-2-2-3.5-2.5-.478-.16-.755.081-.99.284-.172.15-.322.279-.51.216-.445-.148-2.5-2-1.5-2.5.78-.39.952-.171 1.227.182.078.099.163.208.273.318.609.304.662-.132.723-.633.039-.322.081-.671.277-.867.434-.434 1.265-.791 2.028-1.12.712-.306 1.365-.587 1.579-.88A7 7 0 1 1 2.04 4.327Z"/>
    </svg>
    """
  end

  defp visibility_icon_small(%{visibility: "friends"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="currentColor" viewBox="0 0 16 16">
      <path d="M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7Zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm-5.784 6A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216ZM4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z"/>
    </svg>
    """
  end

  defp visibility_icon_small(%{visibility: "private"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="currentColor" viewBox="0 0 16 16">
      <path d="M8 1a2 2 0 0 1 2 2v4H6V3a2 2 0 0 1 2-2Zm3 6V3a3 3 0 0 0-6 0v4a2 2 0 0 0-2 2v5a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2Z"/>
    </svg>
    """
  end

  defp visibility_icon_small(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="currentColor" viewBox="0 0 16 16">
      <path d="M8 0a8 8 0 1 0 0 16A8 8 0 0 0 8 0ZM2.04 4.326c.325 1.329 2.532 2.54 3.717 3.19.48.263.793.434.743.484-.08.08-.162.158-.242.234-.416.396-.787.749-.758 1.266.035.634.618.824 1.214 1.017.577.188 1.168.38 1.286.983.082.417-.075.988-.22 1.52-.215.782-.406 1.48.22 1.48 1.5-.5 3.798-3.186 4-5 .138-1.243-2-2-3.5-2.5-.478-.16-.755.081-.99.284-.172.15-.322.279-.51.216-.445-.148-2.5-2-1.5-2.5.78-.39.952-.171 1.227.182.078.099.163.208.273.318.609.304.662-.132.723-.633.039-.322.081-.671.277-.867.434-.434 1.265-.791 2.028-1.12.712-.306 1.365-.587 1.579-.88A7 7 0 1 1 2.04 4.327Z"/>
    </svg>
    """
  end

  # ============== VISIBILITY BADGE ==============

  attr :visibility, :string, required: true

  defp visibility_badge(%{visibility: "public"} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] md:text-xs font-medium bg-base-200 text-base-content/60">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-2.5 w-2.5 md:h-3 md:w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418" />
      </svg>
      <span class="hidden md:inline">Public</span>
    </span>
    """
  end

  defp visibility_badge(%{visibility: "friends"} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] md:text-xs font-medium bg-info/10 text-info">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-2.5 w-2.5 md:h-3 md:w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
      </svg>
      <span class="hidden md:inline">Amis</span>
    </span>
    """
  end

  defp visibility_badge(%{visibility: "private"} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] md:text-xs font-medium bg-warning/10 text-warning">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-2.5 w-2.5 md:h-3 md:w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
      </svg>
      <span class="hidden md:inline">Privé</span>
    </span>
    """
  end

  defp visibility_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] md:text-xs font-medium bg-base-200 text-base-content/60">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-2.5 w-2.5 md:h-3 md:w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418" />
      </svg>
      <span class="hidden md:inline">Public</span>
    </span>
    """
  end

  # ============== POST TEXT ==============

  attr :post, :map, required: true

  defp post_text(assigns) do
    ~H"""
    <div :if={@post.title || @post.body} class="px-3 pb-2 space-y-1">
      <p :if={@post.title} class="text-[15px] text-base-content font-semibold leading-snug">
        {@post.title}
      </p>
      <p :if={@post.body} class="text-[15px] text-base-content leading-snug">
        {@post.body}
      </p>
    </div>
    """
  end

  # ============== POST IMAGES ==============

  attr :images, :list, required: true
  attr :post_id, :integer, default: nil
  attr :in_modal, :boolean, default: false

  def post_images(%{images: []} = assigns), do: ~H""

  def post_images(%{images: [_image]} = assigns) do
    ~H"""
    <div
      class="cursor-pointer"
      phx-click={if @in_modal, do: "open_image_preview", else: "open_comments"}
      phx-value-src={"/uploads/posts/#{@images |> List.first() |> Map.get(:filename)}"}
      phx-value-id={@post_id}
    >
      <img
        src={"/uploads/posts/#{@images |> List.first() |> Map.get(:filename)}"}
        alt="Image du post"
        class="w-full max-h-[500px] object-cover"
      />
    </div>
    """
  end

  def post_images(%{images: images} = assigns) when length(images) == 2 do
    ~H"""
    <div class="grid grid-cols-2 gap-[1px] bg-base-300">
      <div
        :for={image <- @images}
        class="cursor-pointer"
        phx-click={if @in_modal, do: "open_image_preview", else: "open_comments"}
        phx-value-src={"/uploads/posts/#{image.filename}"}
        phx-value-id={@post_id}
      >
        <img
          src={"/uploads/posts/#{image.filename}"}
          alt="Image du post"
          class="w-full h-[200px] object-cover"
        />
      </div>
    </div>
    """
  end

  def post_images(%{images: images} = assigns) when length(images) == 3 do
    ~H"""
    <div class="grid grid-cols-2 gap-[1px] bg-base-300">
      <div
        class="row-span-2 cursor-pointer"
        phx-click={if @in_modal, do: "open_image_preview", else: "open_comments"}
        phx-value-src={"/uploads/posts/#{Enum.at(@images, 0).filename}"}
        phx-value-id={@post_id}
      >
        <img
          src={"/uploads/posts/#{Enum.at(@images, 0).filename}"}
          alt="Image du post"
          class="w-full h-full object-cover"
        />
      </div>
      <div
        class="cursor-pointer"
        phx-click={if @in_modal, do: "open_image_preview", else: "open_comments"}
        phx-value-src={"/uploads/posts/#{Enum.at(@images, 1).filename}"}
        phx-value-id={@post_id}
      >
        <img
          src={"/uploads/posts/#{Enum.at(@images, 1).filename}"}
          alt="Image du post"
          class="w-full h-[150px] object-cover"
        />
      </div>
      <div
        class="cursor-pointer"
        phx-click={if @in_modal, do: "open_image_preview", else: "open_comments"}
        phx-value-src={"/uploads/posts/#{Enum.at(@images, 2).filename}"}
        phx-value-id={@post_id}
      >
        <img
          src={"/uploads/posts/#{Enum.at(@images, 2).filename}"}
          alt="Image du post"
          class="w-full h-[150px] object-cover"
        />
      </div>
    </div>
    """
  end

  def post_images(assigns) do
    extra_count = length(assigns.images) - 4
    assigns = assign(assigns, :extra_count, extra_count)

    ~H"""
    <div class="grid grid-cols-2 gap-[1px] bg-base-300">
      <%= for {image, index} <- Enum.take(@images, 4) |> Enum.with_index() do %>
        <div
          class="relative cursor-pointer"
          phx-click={if @in_modal, do: "open_image_preview", else: "open_comments"}
          phx-value-src={"/uploads/posts/#{image.filename}"}
          phx-value-id={@post_id}
        >
          <img
            src={"/uploads/posts/#{image.filename}"}
            alt="Image du post"
            class="w-full h-[150px] object-cover"
          />
          <div
            :if={index == 3 and @extra_count > 0}
            class="absolute inset-0 bg-black/50 flex items-center justify-center"
          >
            <span class="text-white text-2xl font-semibold">+{@extra_count}</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # ============== POST MENU ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true

  defp post_menu(assigns) do
    is_owner = assigns.post.user_id == assigns.current_user.id
    assigns = assign(assigns, :is_owner, is_owner)

    ~H"""
    <div class="dropdown dropdown-end">
      <button tabindex="0" type="button" class="w-8 h-8 rounded-full flex items-center justify-center text-base-content/50 hover:bg-base-200">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="currentColor" viewBox="0 0 16 16">
          <path d="M3 9.5a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm5 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm5 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3z"/>
        </svg>
      </button>
      <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-xl z-[1] w-48 p-1.5 shadow-xl border border-base-200">
        <!-- Owner actions -->
        <li :if={@is_owner}>
          <button phx-click="edit_post" phx-value-id={@post.id} class="text-[13px] py-2 flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            Modifier
          </button>
        </li>
        <li :if={@is_owner}>
          <button phx-click="delete" phx-value-id={@post.id} data-confirm="Supprimer ce post ?" class="text-[13px] py-2 text-error flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
            Supprimer
          </button>
        </li>
        <!-- Non-owner actions -->
        <li :if={!@is_owner}>
          <button phx-click="report_post" phx-value-id={@post.id} phx-value-type="post" class="text-[13px] py-2 flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9" />
            </svg>
            Signaler la publication
          </button>
        </li>
        <li :if={!@is_owner}>
          <button phx-click="block_user_from_post" phx-value-id={@post.user_id} class="text-[13px] py-2 text-error flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
            </svg>
            Bloquer @{@post.user.name}
          </button>
        </li>
      </ul>
    </div>
    """
  end

  # ============== PROFILE LINK ==============

  attr :user_id, :integer, required: true
  slot :inner_block, required: true

  def profile_link(assigns) do
    ~H"""
    <a href={~p"/profile/#{@user_id}"} class="contents">
      {render_slot(@inner_block)}
    </a>
    """
  end

  # ============== USER AVATAR ==============

  attr :name, :string, required: true
  attr :avatar, :string, default: nil
  attr :size, :string, default: "w-10 h-10"
  attr :online, :boolean, default: false

  def user_avatar(assigns) do
    colors = ["bg-blue-500", "bg-green-500", "bg-purple-500", "bg-pink-500", "bg-orange-500", "bg-teal-500"]
    color_index = :erlang.phash2(assigns.name, length(colors))
    color = Enum.at(colors, color_index)
    assigns = assign(assigns, :bg_color, color)

    ~H"""
    <%= if @online do %>
      <div class={"relative flex-shrink-0 #{@size}"}>
        <%= if @avatar do %>
          <div class="w-full h-full rounded-full overflow-hidden">
            <img src={"/uploads/avatars/#{@avatar}"} alt={@name} class="w-full h-full object-cover" />
          </div>
        <% else %>
          <div class={"w-full h-full rounded-full #{@bg_color} flex items-center justify-center"}>
            <span class="text-white font-semibold text-sm">
              {String.first(@name) |> String.upcase()}
            </span>
          </div>
        <% end %>
        <span class="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-green-500 border-2 border-base-100"></span>
      </div>
    <% else %>
      <%= if @avatar do %>
        <div class={"#{@size} rounded-full overflow-hidden flex-shrink-0"}>
          <img src={"/uploads/avatars/#{@avatar}"} alt={@name} class="w-full h-full object-cover" />
        </div>
      <% else %>
        <div class={"#{@size} rounded-full #{@bg_color} flex items-center justify-center flex-shrink-0"}>
          <span class="text-white font-semibold text-sm">
            {String.first(@name) |> String.upcase()}
          </span>
        </div>
      <% end %>
    <% end %>
    """
  end

  # ============== EMPTY STATE ==============

  defp empty_state(assigns) do
    ~H"""
    <div class="bg-base-100 rounded-xl md:rounded-2xl shadow-sm p-8 md:p-12 text-center">
      <div class="w-16 h-16 md:w-20 md:h-20 mx-auto mb-4 rounded-full bg-base-200 flex items-center justify-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 md:h-10 md:w-10 text-base-content/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h3 class="text-lg md:text-xl font-semibold text-base-content mb-2">Aucune publication</h3>
      <p class="text-sm md:text-base text-base-content/50 max-w-sm mx-auto">
        Il n'y a pas encore de publications. Soyez le premier à partager quelque chose !
      </p>
    </div>
    """
  end

  # ============== IMAGE PREVIEW MODAL ==============

  attr :src, :string, required: true

  def image_preview_modal(assigns) do
    ~H"""
    <!-- Overlay -->
    <div
      class="fixed inset-0 bg-black/90 z-[70] flex items-center justify-center p-4"
      phx-click="close_image_preview"
    >
      <!-- Close button -->
      <button
        type="button"
        phx-click="close_image_preview"
        class="absolute top-4 right-4 btn btn-circle btn-ghost text-white hover:bg-white/20"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>

      <!-- Image -->
      <img
        src={@src}
        alt="Preview"
        class="max-w-full max-h-[90vh] object-contain rounded-lg shadow-2xl"
        phx-click="close_image_preview"
      />
    </div>
    """
  end

  # ============== DATE POST FORM MODAL ==============

  attr :form, :map, required: true
  attr :current_user, :map, required: true
  attr :uploads, :map, required: true
  attr :editing_post, :map, default: nil

  def date_form_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/50 z-50 flex items-end md:items-center justify-center md:p-4">
      <div
        class="bg-base-100 w-full md:rounded-2xl md:shadow-2xl md:max-w-lg h-full md:h-auto md:max-h-[90vh] flex flex-col overflow-hidden"
        phx-click-away="close_date_modal"
      >
        <!-- Header -->
        <div class="safe-area-top md:rounded-t-2xl">
          <div class="h-14 px-4 border-b border-base-200 flex items-center relative">
            <button type="button" phx-click="close_date_modal" class="w-8 h-8 rounded-full bg-base-200 flex items-center justify-center hover:bg-base-300 transition-colors z-10">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <h3 class="text-lg font-bold text-base-content absolute inset-0 flex items-center justify-center pointer-events-none">
              {if @editing_post, do: "Modifier le Date", else: "Proposer un Date"}
            </h3>
          </div>
        </div>

        <!-- Body -->
        <.form for={@form} phx-submit={if @editing_post, do: "update_date", else: "save_date"} phx-change="validate_date" class="flex flex-col flex-1 overflow-hidden">
          <input :if={@editing_post} type="hidden" name="date[id]" value={@editing_post.id} />
          <div class="p-4 pt-5 sm:p-5 sm:pt-6 flex-1 overflow-y-auto overflow-x-hidden space-y-5">
            <!-- User info + Visibility -->
            <div class="flex items-center justify-between gap-2 min-w-0">
              <div class="flex items-center gap-3 min-w-0 flex-1">
                <.user_avatar name={@current_user.name} avatar={@current_user.avatar} />
                <div class="min-w-0">
                  <div class="font-semibold truncate">{@current_user.name}</div>
                  <div class="text-xs text-base-content/50 font-medium">{if @editing_post, do: "Modifier le date", else: "Nouveau date"}</div>
                </div>
              </div>
              <select name="date[visibility]" class="shrink-0 px-3 py-1.5 bg-base-200/50 border border-base-300 rounded-lg text-sm focus:outline-none focus:border-base-content/30 transition-all appearance-none">
                <option value="public" selected={(@form[:visibility].value || "public") == "public"}>Public</option>
                <option value="friends" selected={@form[:visibility].value == "friends"}>Amis</option>
              </select>
            </div>

            <!-- Date title -->
            <div>
              <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Titre du date *</label>
              <input
                type="text"
                name="date[date_title]"
                value={@form[:date_title].value}
                class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-base placeholder:text-base-content/40 focus:outline-none focus:border-base-content/30 transition-all"
                placeholder="Ex: Resto japonais ce soir !"
                phx-debounce="300"
              />
            </div>

            <!-- Category -->
            <div class="min-w-0">
              <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Catégorie *</label>
              <div class="flex flex-wrap gap-1.5 max-w-full">
                <label
                  :for={cat <- MonApp.Blog.Post.date_categories()}
                  class={"inline-flex items-center gap-1 px-2.5 py-1.5 rounded-full border cursor-pointer transition-all text-xs sm:text-sm #{if @form[:date_category].value == cat, do: "border-base-content bg-base-content/10 text-base-content font-semibold", else: "border-base-300/50 hover:border-base-content/30 bg-base-200/30 text-base-content/70"}"}
                >
                  <input type="radio" name="date[date_category]" value={cat} checked={@form[:date_category].value == cat} class="hidden" />
                  <span>{MonApp.Blog.Post.date_category_emoji(cat)}</span>
                  <span>{MonApp.Blog.Post.date_category_label(cat)}</span>
                </label>
              </div>
            </div>

            <!-- Location & Date/Time -->
            <div class="flex flex-col sm:flex-row gap-3 min-w-0">
              <div class="min-w-0 flex-1">
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Lieu</label>
                <div class="relative">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/30 absolute left-3 top-1/2 -translate-y-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  <input
                    type="text"
                    name="date[date_location]"
                    value={@form[:date_location].value}
                    class="w-full pl-10 pr-3 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm placeholder:text-base-content/40 focus:outline-none focus:border-base-content/30 transition-all"
                    placeholder="Paris 11e..."
                    phx-debounce="300"
                  />
                </div>
              </div>
              <div class="min-w-0 sm:w-[200px] sm:shrink-0">
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Quand ? *</label>
                <div class="relative">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/30 absolute left-3 top-1/2 -translate-y-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  <input
                    type="datetime-local"
                    name="date[date_datetime]"
                    value={format_datetime_local(@form[:date_datetime].value)}
                    class={["w-full pl-10 pr-3 py-3 bg-base-200/50 border rounded-xl text-sm focus:outline-none focus:border-base-content/30 transition-all", if(@form[:date_datetime].errors != [], do: "border-error", else: "border-base-300")]}
                  />
                </div>
                <p :if={@form[:date_datetime].errors != []} class="text-error text-xs mt-1">
                  La date {elem(hd(@form[:date_datetime].errors), 0)}
                </p>
              </div>
            </div>

            <!-- Budget & Spots -->
            <div class="grid grid-cols-2 gap-3 min-w-0">
              <div class="min-w-0">
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Budget</label>
                <select name="date[date_budget]" class="w-full px-3 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-base-content/30 transition-all appearance-none">
                  <option :for={b <- MonApp.Blog.Post.date_budgets()} value={b} selected={@form[:date_budget].value == b}>
                    {MonApp.Blog.Post.date_budget_label(b)}
                  </option>
                </select>
              </div>
              <div class="min-w-0">
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Places</label>
                <input
                  type="number"
                  name="date[date_spots]"
                  value={@form[:date_spots].value || 1}
                  min="1"
                  max="20"
                  class="w-full px-3 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-base-content/30 transition-all"
                />
              </div>
            </div>

            <!-- Gender preference -->
            <div>
              <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Ouvert à</label>
              <select name="date[date_gender_pref]" class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-base focus:outline-none focus:border-base-content/30 transition-all appearance-none">
                <option :for={g <- MonApp.Blog.Post.date_gender_prefs()} value={g} selected={@form[:date_gender_pref].value == g}>
                  {MonApp.Blog.Post.date_gender_pref_label(g)}
                </option>
              </select>
            </div>

            <!-- Age range -->
            <div class="grid grid-cols-2 gap-3 min-w-0">
              <div class="min-w-0">
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Âge min</label>
                <input
                  type="number"
                  name="date[date_age_min]"
                  value={@form[:date_age_min].value}
                  min="18"
                  max="99"
                  placeholder="18"
                  class="w-full px-3 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm placeholder:text-base-content/40 focus:outline-none focus:border-base-content/30 transition-all"
                />
              </div>
              <div class="min-w-0">
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Âge max</label>
                <input
                  type="number"
                  name="date[date_age_max]"
                  value={@form[:date_age_max].value}
                  min="18"
                  max="99"
                  placeholder="99"
                  class="w-full px-3 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm placeholder:text-base-content/40 focus:outline-none focus:border-base-content/30 transition-all"
                />
              </div>
            </div>

            <!-- Description -->
            <div>
              <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Description (optionnel)</label>
              <textarea
                name="date[body]"
                class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-base placeholder:text-base-content/40 focus:outline-none focus:border-base-content/30 transition-all resize-none min-h-[80px]"
                placeholder="Décris ton date idéal..."
                phx-debounce="300"
              >{@form[:body].value}</textarea>
            </div>

            <!-- Photo upload -->
            <div>
              <span class="text-sm font-medium text-base-content/70 mb-1.5 block">Photo (optionnel)</span>

              <%
                existing_images = if @editing_post && @editing_post.images, do: @editing_post.images, else: []
                new_entries = @uploads.date_images.entries
                has_any = existing_images != [] || new_entries != []
                total_count = length(existing_images) + length(new_entries)
              %>

              <div :if={has_any} class="flex gap-2 flex-wrap mb-3">
                <!-- Existing images (from DB) -->
                <div :for={img <- existing_images} class="relative group w-20 h-20">
                  <img src={"/uploads/posts/#{img.filename}"} class="w-full h-full object-cover rounded-xl" />
                  <button
                    type="button"
                    phx-click="remove_date_image"
                    phx-value-id={img.id}
                    class="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-base-100 border border-base-300 shadow-sm flex items-center justify-center hover:bg-error hover:text-white hover:border-error transition-colors"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                <!-- New uploads (preview) -->
                <div :for={entry <- new_entries} class="relative group w-20 h-20">
                  <.live_img_preview entry={entry} class="w-full h-full object-cover rounded-xl" />
                  <button
                    type="button"
                    phx-click="cancel-date-upload"
                    phx-value-ref={entry.ref}
                    class="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-base-100 border border-base-300 shadow-sm flex items-center justify-center hover:bg-error hover:text-white hover:border-error transition-colors"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                <!-- Add more button -->
                <label
                  :if={total_count < 4}
                  class="w-20 h-20 border-2 border-dashed border-base-300 rounded-xl cursor-pointer flex items-center justify-center hover:border-base-content/30 hover:bg-base-200 transition-all"
                  phx-drop-target={@uploads.date_images.ref}
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-base-content/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                  </svg>
                  <.live_file_input upload={@uploads.date_images} class="hidden" />
                </label>
              </div>

              <!-- Empty state upload -->
              <label
                :if={!has_any}
                class="flex flex-col items-center justify-center w-full py-6 border-2 border-dashed border-base-300 rounded-xl cursor-pointer hover:border-base-content/30 hover:bg-base-200 transition-all group"
                phx-drop-target={@uploads.date_images.ref}
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-base-content/30 group-hover:text-base-content/50 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <span class="text-xs text-base-content/40 mt-1.5">Ajouter une photo</span>
                <.live_file_input upload={@uploads.date_images} class="hidden" />
              </label>

              <div :for={err <- upload_errors(@uploads.date_images)} class="text-error text-xs mt-1">
                {upload_error_to_string(err)}
              </div>
            </div>

          </div>

          <!-- Footer -->
          <div class="p-4 border-t border-base-200 safe-area-bottom">
            <button type="submit" class="btn w-full border-0 bg-base-content text-base-100 hover:bg-pink-500 hover:text-white rounded-xl transition-all duration-300">
              {if @editing_post, do: "Enregistrer les modifications", else: "Publier le date"}
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  # ============== DATE POST CARD ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true
  attr :online_user_ids, :list, default: []

  def date_post_card(assigns) do
    accepted_count = Enum.count(assigns.post.date_applications || [], fn a -> a.status == "accepted" end)
    pending_count = Enum.count(assigns.post.date_applications || [], fn a -> a.status == "pending" end)
    user_application = Enum.find(assigns.post.date_applications || [], fn a -> a.user_id == assigns.current_user.id end)
    is_owner = assigns.post.user_id == assigns.current_user.id
    is_full = assigns.post.date_status == "full" or accepted_count >= assigns.post.date_spots
    is_past = assigns.post.date_status in ["completed", "cancelled"]
    countdown = date_countdown(assigns.post.date_datetime)

    assigns = assigns
      |> assign(:accepted_count, accepted_count)
      |> assign(:pending_count, pending_count)
      |> assign(:user_application, user_application)
      |> assign(:is_owner, is_owner)
      |> assign(:is_full, is_full)
      |> assign(:is_past, is_past)
      |> assign(:countdown, countdown)

    ~H"""
    <article id={"post-#{@post.id}"} class={"bg-base-100 rounded-xl shadow-lg overflow-hidden border border-base-200 #{if @is_past, do: "opacity-70", else: ""}"}>
      <!-- Header -->
      <div class="p-5 flex items-center justify-between border-b border-base-200">
        <div class="flex items-center gap-3.5">
          <a href={~p"/profile/#{@post.user.id}"} class="relative shrink-0">
            <div class="w-12 h-12 rounded-full border-2 border-pink-500 p-0.5">
              <.user_avatar name={@post.user.name} avatar={@post.user.avatar} size="w-full h-full" />
            </div>
            <span :if={@post.user_id in @online_user_ids} class="absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full bg-green-500 border-2 border-base-100"></span>
          </a>
          <div>
            <a href={~p"/profile/#{@post.user.id}"} class="font-bold text-base hover:text-pink-500 transition-colors">{@post.user.name}</a>
            <p class="text-base-content/50 text-sm">{time_ago(@post.inserted_at)} · {MonApp.Blog.Post.date_category_label(@post.date_category)}</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <div class={"badge #{status_badge_class(@post.date_status)} badge-sm"}>
            {MonApp.Blog.Post.date_status_label(@post.date_status)}
          </div>
          <div class="dropdown dropdown-end">
            <label tabindex="0" class="text-base-content/40 hover:text-base-content transition-colors cursor-pointer">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 5v.01M12 12v.01M12 19v.01" />
              </svg>
            </label>
            <ul tabindex="0" class="dropdown-content menu p-1.5 shadow-xl bg-base-100 rounded-xl w-48 border border-base-200 z-50">
              <!-- Owner -->
              <li :if={@is_owner}>
                <button phx-click="edit_date" phx-value-id={@post.id} class="flex items-center gap-2 text-sm">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                  Modifier
                </button>
              </li>
              <li :if={@is_owner}>
                <button phx-click="delete_date" phx-value-id={@post.id} data-confirm="Supprimer ce date ?" class="flex items-center gap-2 text-sm text-error">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                  Supprimer
                </button>
              </li>
              <!-- Non-owner -->
              <li :if={!@is_owner}>
                <button phx-click="report_post" phx-value-id={@post.id} phx-value-type="date" class="flex items-center gap-2 text-sm">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9" />
                  </svg>
                  Signaler ce date
                </button>
              </li>
              <li :if={!@is_owner}>
                <button phx-click="block_user_from_post" phx-value-id={@post.user_id} class="flex items-center gap-2 text-sm text-error">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                  </svg>
                  Bloquer @{@post.user.name}
                </button>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Content -->
      <div class="p-5">
        <div class="flex flex-col gap-4">
          <!-- Title & Places badge -->
          <div class="flex justify-between items-start gap-3">
            <div class="flex-1">
              <h3 class="text-2xl font-extrabold tracking-tight">
                {MonApp.Blog.Post.date_category_emoji(@post.date_category)} {@post.date_title}
              </h3>
              <p :if={@post.body} class="text-base-content/60 mt-1.5 leading-relaxed text-sm">{@post.body}</p>
            </div>
            <div class="flex flex-col items-center bg-base-200 px-3.5 py-2 rounded-xl border border-base-300 shrink-0">
              <span class="text-[10px] font-bold uppercase tracking-wider text-base-content/50">{if @post.date_spots > 1, do: "Places", else: "Place"}</span>
              <span class="text-lg font-black text-blue-500">{@accepted_count}/{@post.date_spots}</span>
            </div>
          </div>

          <!-- Info badges -->
          <div class="flex flex-wrap gap-2">
            <div class="flex items-center gap-1.5 bg-blue-500/10 text-blue-600 px-3.5 py-1.5 rounded-full text-sm font-semibold">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              {@post.date_location}
            </div>
            <div class={"flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-sm font-semibold #{if @is_past, do: "bg-base-200 text-base-content/40", else: "bg-pink-500/10 text-pink-600"}"}>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span>{format_date_datetime(@post.date_datetime)}</span>
              <span :if={@countdown} class={if @is_past, do: "opacity-60", else: "opacity-40"}>|</span>
              <span :if={@countdown}>{@countdown.text}</span>
            </div>
            <div class="flex items-center gap-1.5 bg-base-200 text-base-content/70 px-3.5 py-1.5 rounded-full text-sm font-semibold">
              Budget: {MonApp.Blog.Post.date_budget_label(@post.date_budget || "low")}
            </div>
            <div class="flex items-center gap-1.5 bg-base-200 text-base-content/70 px-3.5 py-1.5 rounded-full text-sm font-semibold">
              {MonApp.Blog.Post.date_gender_pref_label(@post.date_gender_pref || "any")}
            </div>
            <div :if={@post.date_age_min || @post.date_age_max} class="flex items-center gap-1.5 bg-base-200 text-base-content/70 px-3.5 py-1.5 rounded-full text-sm font-semibold">
              {if @post.date_age_min, do: "#{@post.date_age_min}", else: "18"}-{if @post.date_age_max, do: "#{@post.date_age_max}", else: "99"} ans
            </div>
          </div>

          <!-- Date image -->
          <div
            :if={@post.images != [] && List.first(@post.images)}
            class="w-full h-48 rounded-xl overflow-hidden relative"
          >
            <img
              src={"/uploads/posts/#{List.first(@post.images).filename}"}
              alt="Date photo"
              class="w-full h-full object-cover"
            />
            <div class="absolute inset-0 bg-black/5"></div>
          </div>
        </div>
      </div>

      <!-- Action footer -->
      <div class={"px-5 py-4 bg-base-200/50 border-t border-base-200 flex items-center #{if !@is_owner && @user_application && @user_application.status != "pending", do: "justify-center", else: "flex-col sm:flex-row gap-3 justify-between"}"}>
        <!-- Left: interested people info or pending status -->
        <div :if={!@is_owner && @user_application && @user_application.status == "pending"} class="flex items-center gap-2 text-base-content/50 text-sm">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          En attente...
        </div>
        <div :if={!@user_application || @is_owner} class="flex items-center">
          <!-- Owner: voir les avatars -->
          <div :if={@is_owner && (@accepted_count > 0 || @pending_count > 0)} class="flex items-center">
            <div class="flex -space-x-2.5">
              <div
                :for={app <- Enum.take(Enum.filter(@post.date_applications || [], fn a -> a.status == "accepted" end), 3)}
                class="w-8 h-8 rounded-full border-2 border-base-100 overflow-hidden"
              >
                <.user_avatar name={app.user.name} avatar={app.user.avatar} size="w-full h-full" />
              </div>
              <div
                :if={(@accepted_count + @pending_count) > 3}
                class="w-8 h-8 rounded-full border-2 border-base-100 bg-pink-500 text-white flex items-center justify-center text-[10px] font-bold"
              >
                +{@accepted_count + @pending_count - 3}
              </div>
            </div>
            <span class="pl-3 text-sm text-base-content/50 font-medium">
              {cond do
                @is_full && @accepted_count > 0 ->
                  "#{@accepted_count}/#{@post.date_spots} acceptée#{if @accepted_count > 1, do: "s", else: ""} · Complet"
                @accepted_count > 0 && @pending_count > 0 ->
                  "#{@accepted_count}/#{@post.date_spots} acceptée#{if @accepted_count > 1, do: "s", else: ""} · #{@pending_count} en attente"
                @accepted_count > 0 ->
                  "#{@accepted_count}/#{@post.date_spots} acceptée#{if @accepted_count > 1, do: "s", else: ""}"
                true ->
                  "#{@pending_count} candidature#{if @pending_count > 1, do: "s", else: ""}"
              end}
            </span>
          </div>
          <!-- Non-owner: juste un compteur, pas d'avatars -->
          <div :if={!@is_owner && (@accepted_count > 0 || @pending_count > 0)} class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-full bg-pink-500/10 flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-pink-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <span class="text-sm text-base-content/50 font-medium">
              {total = @accepted_count + @pending_count; "#{total} personne#{if total > 1, do: "s", else: ""} intéressée#{if total > 1, do: "s", else: ""}"}
            </span>
          </div>
          <!-- Personne -->
          <span :if={@accepted_count == 0 && @pending_count == 0} class="text-sm text-base-content/40">
            {if @is_owner, do: "En attente de candidatures...", else: "Soyez le premier !"}
          </span>
        </div>

        <!-- Right: action button -->
        <div class="w-full sm:w-auto">
          <!-- Owner: view applications -->
          <button
            :if={@is_owner && (@pending_count > 0 || @accepted_count > 0)}
            phx-click="view_date_applications"
            phx-value-id={@post.id}
            phx-hook="ScrollLock"
            id={"view-apps-btn-#{@post.id}"}
            class="w-full sm:w-auto bg-base-content text-base-100 px-6 py-2.5 rounded-xl font-bold hover:bg-pink-500 hover:text-white transition-all duration-300 shadow-md flex items-center justify-center gap-2 text-sm"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
            Voir les candidatures ({@pending_count + @accepted_count})
          </button>

          <div :if={@is_owner && @pending_count == 0 && @accepted_count == 0} class="text-center text-sm text-base-content/50 py-1">
            En attente de candidatures...
          </div>

          <!-- Not owner -->
          <!-- Pending -->
          <button
            :if={!@is_owner && @user_application && @user_application.status == "pending"}
            phx-click="cancel_date_application"
            phx-value-post-id={@post.id}
            class="w-full sm:w-auto bg-base-content text-base-100 px-6 py-2.5 rounded-xl font-bold hover:bg-pink-500 hover:text-white transition-all duration-300 shadow-md flex items-center justify-center gap-2 text-sm"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 1.41.5 2.7 1.33 3.73L12 21.35l8.67-9.12C21.5 11.2 22 9.91 22 8.5 22 5.42 19.58 3 16.5 3zM12 18.35l-6.93-7.29C4.39 10.32 4 9.44 4 8.5 4 6.57 5.57 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5 18.43 5 20 6.57 20 8.5c0 .94-.39 1.82-1.07 2.56L12 18.35z" />
            </svg>
            Je ne suis plus intéressé(e)
          </button>

          <!-- Accepted -->
          <div :if={!@is_owner && @user_application && @user_application.status == "accepted"} class="flex items-center justify-center gap-2 text-sm text-emerald-600 font-medium py-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
            </svg>
            Accepté
          </div>

          <!-- Rejected -->
          <div :if={!@is_owner && @user_application && @user_application.status == "rejected"} class="text-center text-sm text-base-content/50 py-2">
            Candidature déclinée
          </div>

          <!-- Can apply -->
          <button
            :if={!@is_owner && !@user_application && !@is_full && @post.date_status == "open"}
            phx-click="open_apply_modal"
            phx-value-id={@post.id}
            class="w-full sm:w-auto bg-base-content text-base-100 px-6 py-2.5 rounded-xl font-bold hover:bg-pink-500 hover:text-white transition-all duration-300 shadow-md flex items-center justify-center gap-2 text-sm"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
            Je suis intéressé(e) !
          </button>

          <!-- Full -->
          <div :if={!@is_owner && !@user_application && @is_full} class="text-center text-sm text-base-content/50 py-2">
            Complet
          </div>
        </div>
      </div>
    </article>
    """
  end

  defp status_badge_class("open"), do: "badge-success"
  defp status_badge_class("full"), do: "badge-warning"
  defp status_badge_class("completed"), do: "badge-ghost opacity-60"
  defp status_badge_class("cancelled"), do: "badge-error"
  defp status_badge_class(_), do: "badge-ghost"

  defp date_countdown(nil), do: nil
  defp date_countdown(datetime) do
    now = NaiveDateTime.utc_now()
    diff_seconds = NaiveDateTime.diff(datetime, now)
    diff_hours = div(diff_seconds, 3600)
    diff_days = div(diff_seconds, 86400)

    cond do
      diff_seconds < 0 ->
        past_days = abs(diff_days)
        text = cond do
          past_days == 0 -> "Terminé aujourd'hui"
          past_days == 1 -> "Hier"
          true -> "Il y a #{past_days}j"
        end
        %{text: text, text_class: "text-base-content/40"}

      diff_days == 0 && diff_hours <= 0 ->
        %{text: "Bientôt", text_class: "text-success font-bold animate-pulse"}

      diff_days == 0 ->
        %{text: "Aujourd'hui", text_class: "text-success font-bold"}

      diff_days == 1 ->
        %{text: "Demain", text_class: "text-orange-500 font-bold"}

      diff_days <= 7 ->
        %{text: "Dans #{diff_days}j", text_class: "text-blue-500"}

      diff_days <= 30 ->
        weeks = div(diff_days, 7)
        %{text: "Dans #{weeks} sem.", text_class: "text-base-content/50"}

      true ->
        %{text: "Dans #{div(diff_days, 30)} mois", text_class: "text-base-content/50"}
    end
  end

  defp format_date_datetime(nil), do: "À définir"
  defp format_date_datetime(datetime) do
    Calendar.strftime(datetime, "%d/%m à %Hh%M")
  end

  # Formate une valeur pour input datetime-local (YYYY-MM-DDTHH:MM)
  defp format_datetime_local(nil), do: nil
  defp format_datetime_local(""), do: nil
  defp format_datetime_local(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%dT%H:%M")
  defp format_datetime_local(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%dT%H:%M")
  defp format_datetime_local(value) when is_binary(value) do
    # Si c'est déjà un string du form HTML, le garder tel quel (tronquer au format attendu)
    value |> String.slice(0, 16)
  end

  # ============== DATE APPLICATION MODAL ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true

  def date_apply_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center">
      <div
        class="bg-base-100 rounded-t-2xl sm:rounded-xl shadow-2xl w-full max-w-md"
        phx-click-away="close_apply_modal"
      >
        <div class="p-4 border-b border-base-200">
          <h3 class="text-lg font-bold flex items-center gap-2">
            <span>💘</span> Postuler au date
          </h3>
          <p class="text-sm text-base-content/60 mt-1">{@post.date_title}</p>
        </div>

        <form phx-submit="submit_date_application" class="p-5 space-y-4">
          <input type="hidden" name="post_id" value={@post.id} />
          <div>
            <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Un petit message ? (optionnel)</label>
            <textarea
              name="message"
              class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm placeholder:text-base-content/40 focus:outline-none focus:border-base-content/30 transition-all resize-none"
              placeholder="Salut ! Je suis partant(e), j'adore la cuisine japonaise..."
              maxlength="500"
              rows="3"
            ></textarea>
          </div>
          <div class="flex gap-2">
            <button type="button" phx-click="close_apply_modal" class="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium text-base-content/60 hover:bg-base-200 transition-all">Annuler</button>
            <button type="submit" class="flex-1 bg-base-content text-base-100 px-4 py-2.5 rounded-xl font-bold text-sm hover:bg-pink-500 hover:text-white transition-all duration-300 shadow-md flex items-center justify-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
              </svg>
              Postuler
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  # ============== DATE APPLICATIONS LIST MODAL ==============

  attr :post, :map, required: true
  attr :applications, :list, required: true
  attr :current_user, :map, required: true

  def date_applications_modal(assigns) do
    pending = Enum.filter(assigns.applications, fn a -> a.status == "pending" end)
    accepted = Enum.filter(assigns.applications, fn a -> a.status == "accepted" end)
    rejected = Enum.filter(assigns.applications, fn a -> a.status == "rejected" end)
    is_full = length(accepted) >= assigns.post.date_spots

    assigns = assigns
      |> assign(:pending, pending)
      |> assign(:accepted, accepted)
      |> assign(:rejected, rejected)
      |> assign(:is_full, is_full)

    ~H"""
    <div class="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center">
      <div
        class="bg-base-100 rounded-t-2xl sm:rounded-2xl shadow-2xl w-full max-w-lg max-h-[85vh] flex flex-col border border-base-200"
        phx-click-away="close_date_applications"
      >
        <!-- Header -->
        <div class="p-4 border-b border-base-200 flex items-center justify-between">
          <div>
            <h3 class="text-lg font-bold flex items-center gap-2">
              <span>{MonApp.Blog.Post.date_category_emoji(@post.date_category)}</span> {@post.date_title}
            </h3>
            <p class="text-sm text-base-content/60 mt-1">
              {length(@accepted)}/{@post.date_spots} place{if @post.date_spots > 1, do: "s", else: ""}
              {if @is_full, do: " · Complet", else: if(length(@pending) > 0, do: " · #{length(@pending)} en attente", else: "")}
            </p>
          </div>
          <button type="button" phx-click="close_date_applications" class="text-base-content/40 hover:text-base-content transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-5 space-y-5">
          <!-- Accepted (toujours en premier) -->
          <div :if={@accepted != []}>
            <h4 class="text-xs font-bold uppercase tracking-wider text-emerald-500 mb-3 flex items-center gap-1.5">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
              </svg>
              Acceptés ({length(@accepted)})
            </h4>
            <div class="space-y-2.5">
              <div :for={app <- @accepted} class="flex items-center gap-3 p-3.5 bg-emerald-500/5 rounded-xl border border-emerald-200">
                <a href={~p"/profile/#{app.user.id}"} class="shrink-0">
                  <div class="w-11 h-11 rounded-full border-2 border-emerald-400 p-0.5">
                    <.user_avatar name={app.user.name} avatar={app.user.avatar} size="w-full h-full" />
                  </div>
                </a>
                <div class="flex-1 min-w-0">
                  <a href={~p"/profile/#{app.user.id}"} class="font-bold text-sm hover:text-pink-500 transition-colors">{app.user.name}</a>
                  <p :if={app.message} class="text-xs text-base-content/60 mt-0.5">{app.message}</p>
                </div>
                <span class="px-2.5 py-1 bg-emerald-500/10 text-emerald-600 text-xs font-bold rounded-full">Accepté</span>
              </div>
            </div>
          </div>

          <!-- Pending : avec actions si pas complet, simple liste si complet -->
          <div :if={@pending != [] && !@is_full}>
            <h4 class="text-xs font-bold uppercase tracking-wider text-amber-500 mb-3 flex items-center gap-1.5">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              En attente ({length(@pending)})
            </h4>
            <div class="space-y-2.5">
              <div :for={app <- @pending} class="flex items-center gap-3 p-3.5 bg-base-200/50 rounded-xl border border-base-200 hover:border-pink-300 transition-colors">
                <a href={~p"/profile/#{app.user.id}"} class="shrink-0">
                  <div class="w-11 h-11 rounded-full border-2 border-amber-400 p-0.5">
                    <.user_avatar name={app.user.name} avatar={app.user.avatar} size="w-full h-full" />
                  </div>
                </a>
                <div class="flex-1 min-w-0">
                  <a href={~p"/profile/#{app.user.id}"} class="font-bold text-sm hover:text-pink-500 transition-colors">{app.user.name}</a>
                  <p :if={app.message} class="text-xs text-base-content/60 mt-0.5 line-clamp-2">{app.message}</p>
                  <p class="text-[11px] text-base-content/40 mt-0.5">{time_ago(app.inserted_at)}</p>
                </div>
                <div class="shrink-0">
                  <button
                    phx-click="accept_date_application"
                    phx-value-id={app.id}
                    class="px-3.5 py-1.5 bg-emerald-500 text-white text-xs font-bold rounded-lg hover:bg-emerald-600 transition-colors shadow-sm"
                  >Accepter</button>
                </div>
              </div>
            </div>
          </div>

          <!-- Pending quand complet : simple liste sans actions ni statut "en attente" -->
          <div :if={@pending != [] && @is_full}>
            <h4 class="text-xs font-bold uppercase tracking-wider text-base-content/40 mb-3 flex items-center gap-1.5">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              Autres candidats ({length(@pending)})
            </h4>
            <div class="space-y-2">
              <div :for={app <- @pending} class="flex items-center gap-3 p-3 bg-base-200/30 rounded-xl">
                <a href={~p"/profile/#{app.user.id}"} class="shrink-0">
                  <div class="w-10 h-10 rounded-full border-2 border-base-300 p-0.5">
                    <.user_avatar name={app.user.name} avatar={app.user.avatar} size="w-full h-full" />
                  </div>
                </a>
                <div class="flex-1 min-w-0">
                  <a href={~p"/profile/#{app.user.id}"} class="font-medium text-sm text-base-content/60 hover:text-pink-500 transition-colors">{app.user.name}</a>
                  <p :if={app.message} class="text-xs text-base-content/40 mt-0.5 line-clamp-1">{app.message}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Declined -->
          <div :if={@rejected != []}>
            <h4 class="text-xs font-bold uppercase tracking-wider text-base-content/30 mb-3">Déclinés ({length(@rejected)})</h4>
            <div class="space-y-2">
              <div :for={app <- @rejected} class="flex items-center gap-3 p-3 bg-base-200/30 rounded-xl opacity-50">
                <div class="w-10 h-10 rounded-full bg-base-300 flex items-center justify-center shrink-0">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <div class="flex-1">
                  <span class="text-sm text-base-content/40">{app.user.name}</span>
                </div>
                <span class="text-xs text-base-content/30">Décliné</span>
              </div>
            </div>
          </div>

          <!-- Empty state -->
          <div :if={@pending == [] && @accepted == [] && @rejected == []} class="text-center py-12">
            <div class="w-16 h-16 mx-auto bg-pink-500/10 rounded-full flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-pink-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <p class="text-base-content/40 text-sm">Pas encore de candidatures</p>
            <p class="text-base-content/30 text-xs mt-1">Les personnes intéressées apparaîtront ici</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ============== FIELD ERROR ==============

  attr :field, :map, required: true

  defp field_error(assigns) do
    ~H"""
    <span :for={msg <- @field.errors} class="text-error text-sm">
      {elem(msg, 0)}
    </span>
    """
  end
end
