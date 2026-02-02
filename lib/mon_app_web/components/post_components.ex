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
    <div
      class="card bg-base-100 shadow-sm mb-6 cursor-pointer hover:shadow-md transition-shadow"
      phx-click="open_post_modal"
    >
      <div class="card-body py-4">
        <div class="flex items-center gap-3">
          <.user_avatar name={@current_user.name} />
          <div class="flex-1 bg-base-200 rounded-full px-4 py-2.5 text-base-content/50 hover:bg-base-300 transition-colors">
            Quoi de neuf, {@current_user.name |> String.split() |> List.first()} ?
          </div>
        </div>
        <div class="divider my-2 before:bg-white/20 after:bg-white/20"></div>
        <div class="flex justify-around">
          <button type="button" class="btn btn-ghost btn-sm gap-2 text-success">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            Photo
          </button>
          <button type="button" class="btn btn-ghost btn-sm gap-2 text-warning">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Humeur
          </button>
        </div>
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
              <.user_avatar name={@current_user.name} />
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
              <.user_avatar name={@current_user.name} />
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
        <.user_avatar name={@reaction.user.name} size="w-8 h-8" />
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
        <.user_avatar name={@reaction.user.name} />
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
              <.user_avatar name={@post.user.name} />
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <span class="font-semibold">{@post.user.name}</span>
                  <.visibility_badge visibility={@post.visibility} />
                </div>
                <span class="text-sm text-base-content/50" title={Calendar.strftime(@post.inserted_at, "%d %b %Y à %H:%M")}>
                  {time_ago(@post.inserted_at)}
                </span>
              </div>
            </div>

            <!-- Post body -->
            <div class="mt-3">
              <h3 class="font-semibold text-lg">{@post.title}</h3>
              <p :if={@post.body} class="text-base-content/80 mt-1">{@post.body}</p>
              <.post_images images={@post.images} />
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
            <.user_avatar name={@current_user.name} size="w-9 h-9" />
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
      <.user_avatar name={@comment.user.name} size={if @is_reply, do: "w-6 h-6", else: "w-8 h-8"} />
      <div class="flex-1 min-w-0">
        <!-- Bulle du commentaire -->
        <div class="inline-block max-w-[85%]">
          <div :if={@comment.body && @comment.body != ""} class="bg-base-200 rounded-2xl px-4 py-2">
            <span class="font-semibold text-sm block">{@comment.user.name}</span>
            <p class="text-sm whitespace-pre-wrap break-words">{@comment.body}</p>
          </div>
          <!-- Nom si pas de texte mais image -->
          <span :if={(!@comment.body || @comment.body == "") && @images != []} class="font-semibold text-sm block mb-1">{@comment.user.name}</span>
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

  def post_list(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center gap-2">
        <h2 class="text-xl font-semibold">Fil d'actualité</h2>
        <span class="badge badge-success badge-sm">Live</span>
        <span class="text-base-content/50 text-sm">({length(@posts)} posts)</span>
      </div>

      <.empty_state :if={@posts == []} />

      <.post_item
        :for={post <- @posts}
        post={post}
        current_user={@current_user}
      />
    </div>
    """
  end

  # ============== POST ITEM ==============

  attr :post, :map, required: true
  attr :current_user, :map, required: true

  def post_item(assigns) do
    comment_count = length(assigns.post.comments || [])
    reactions = get_reactions_data(assigns.post, assigns.current_user)
    assigns = assigns
      |> assign(:comment_count, comment_count)
      |> assign(:reactions_data, reactions)

    ~H"""
    <div id={"post-#{@post.id}"} class="card bg-base-100 shadow-sm">
      <div class="card-body">
        <.post_header post={@post} current_user={@current_user} />
        <.post_content post={@post} />
        <.post_actions post={@post} comment_count={@comment_count} current_user={@current_user} reactions_data={@reactions_data} />
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

  # ============== POST ACTIONS ==============

  attr :post, :map, required: true
  attr :comment_count, :integer, required: true
  attr :current_user, :map, required: true
  attr :reactions_data, :map, required: true

  defp post_actions(assigns) do
    ~H"""
    <div class="mt-4 pt-3 border-t border-white/20">
      <!-- Compteur de réactions et commentaires -->
      <div class="flex items-center justify-between text-sm text-base-content/60 mb-2">
        <button
          :if={@reactions_data.total > 0}
          type="button"
          phx-click="open_reactions"
          phx-value-id={@post.id}
          class="flex items-center gap-1 hover:underline cursor-pointer"
        >
          <.reaction_summary counts={@reactions_data.counts} />
          <span>{@reactions_data.total}</span>
        </button>
        <div :if={@comment_count > 0}>
          {@comment_count} commentaire{if @comment_count > 1, do: "s", else: ""}
        </div>
      </div>

      <!-- Boutons d'action -->
      <div class="flex gap-1 border-t border-white/20 pt-2">
        <!-- Bouton réaction avec picker au hover -->
        <div class="dropdown dropdown-top dropdown-hover flex-1">
          <div
            tabindex="0"
            role="button"
            class={"btn btn-ghost btn-sm flex-1 gap-2 w-full #{if @reactions_data.user_reaction, do: "text-primary", else: ""}"}
          >
            <span :if={@reactions_data.user_reaction} class="text-lg">
              {reaction_emoji(@reactions_data.user_reaction.type)}
            </span>
            <svg :if={!@reactions_data.user_reaction} xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
            </svg>
            {if @reactions_data.user_reaction, do: reaction_label(@reactions_data.user_reaction.type), else: "J'aime"}
          </div>
          <!-- Picker de réactions (apparaît au hover) - pb-3 crée une zone de connexion -->
          <div class="dropdown-content pb-3 z-50">
            <div class="bg-base-100 rounded-full shadow-lg border border-white/20 p-1 flex gap-1">
              <button
                :for={type <- reaction_types()}
                type="button"
                phx-click="toggle_reaction"
                phx-value-post-id={@post.id}
                phx-value-type={type}
                onclick="this.closest('.dropdown').querySelector('[tabindex]').blur()"
                class={"btn btn-ghost btn-circle btn-sm hover:scale-125 transition-transform #{if @reactions_data.user_reaction && @reactions_data.user_reaction.type == type, do: "bg-primary/20", else: ""}"}
                title={reaction_label(type)}
              >
                <span class="text-xl">{reaction_emoji(type)}</span>
              </button>
            </div>
          </div>
        </div>

        <button
          type="button"
          phx-click="open_comments"
          phx-value-id={@post.id}
          class="btn btn-ghost btn-sm flex-1 gap-2"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
          </svg>
          Commenter
        </button>
      </div>
    </div>
    """
  end

  # ============== REACTION HELPERS ==============

  attr :counts, :map, required: true

  defp reaction_summary(assigns) do
    # Trier les réactions par nombre (desc) et prendre les 3 premières
    top_reactions = assigns.counts
      |> Enum.sort_by(fn {_type, count} -> count end, :desc)
      |> Enum.take(3)
      |> Enum.map(fn {type, _count} -> type end)

    assigns = assign(assigns, :top_reactions, top_reactions)

    ~H"""
    <div class="flex -space-x-1">
      <span :for={type <- @top_reactions} class="text-sm">{reaction_emoji(type)}</span>
    </div>
    """
  end

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

  defp post_header(assigns) do
    ~H"""
    <div class="flex items-start gap-3">
      <.user_avatar name={@post.user.name} />

      <div class="flex-1">
        <div class="flex items-center gap-2">
          <span class="font-semibold">{@post.user.name}</span>
          <.visibility_badge visibility={@post.visibility} />
        </div>
        <span class="text-sm text-base-content/50" title={Calendar.strftime(@post.inserted_at, "%d %b %Y à %H:%M")}>
          {time_ago(@post.inserted_at)}
        </span>
      </div>

      <.post_menu :if={@post.user_id == @current_user.id} post={@post} />
    </div>
    """
  end

  # ============== VISIBILITY BADGE ==============

  attr :visibility, :string, required: true

  defp visibility_badge(%{visibility: "public"} = assigns) do
    ~H"""
    <span class="badge badge-ghost badge-xs gap-1">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      Public
    </span>
    """
  end

  defp visibility_badge(%{visibility: "friends"} = assigns) do
    ~H"""
    <span class="badge badge-info badge-xs gap-1">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
      Amis
    </span>
    """
  end

  defp visibility_badge(%{visibility: "private"} = assigns) do
    ~H"""
    <span class="badge badge-warning badge-xs gap-1">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
      </svg>
      Privé
    </span>
    """
  end

  defp visibility_badge(assigns) do
    ~H"""
    <span class="badge badge-ghost badge-xs">Public</span>
    """
  end

  # ============== POST CONTENT ==============

  attr :post, :map, required: true

  defp post_content(assigns) do
    ~H"""
    <div class="mt-3">
      <h3 class="font-semibold text-lg">{@post.title}</h3>
      <p :if={@post.body} class="text-base-content/80 mt-1">{@post.body}</p>

      <!-- Images du post -->
      <.post_images images={@post.images} />
    </div>
    """
  end

  # ============== POST IMAGES ==============

  attr :images, :list, required: true

  defp post_images(%{images: []} = assigns), do: ~H""

  defp post_images(%{images: [_image]} = assigns) do
    ~H"""
    <div class="mt-3">
      <img
        src={"/uploads/posts/#{@images |> List.first() |> Map.get(:filename)}"}
        alt="Image du post"
        class="rounded-lg max-h-96 w-auto cursor-pointer hover:opacity-90 transition-opacity"
        phx-click="open_image_preview"
        phx-value-src={"/uploads/posts/#{@images |> List.first() |> Map.get(:filename)}"}
      />
    </div>
    """
  end

  defp post_images(%{images: images} = assigns) when length(images) == 2 do
    ~H"""
    <div class="mt-3 grid grid-cols-2 gap-2">
      <img
        :for={image <- @images}
        src={"/uploads/posts/#{image.filename}"}
        alt="Image du post"
        class="rounded-lg h-48 w-full object-cover cursor-pointer hover:opacity-90 transition-opacity"
        phx-click="open_image_preview"
        phx-value-src={"/uploads/posts/#{image.filename}"}
      />
    </div>
    """
  end

  defp post_images(%{images: images} = assigns) when length(images) == 3 do
    ~H"""
    <div class="mt-3 grid grid-cols-2 gap-2">
      <img
        src={"/uploads/posts/#{Enum.at(@images, 0).filename}"}
        alt="Image du post"
        class="rounded-lg h-48 w-full object-cover row-span-2 cursor-pointer hover:opacity-90 transition-opacity"
        phx-click="open_image_preview"
        phx-value-src={"/uploads/posts/#{Enum.at(@images, 0).filename}"}
      />
      <img
        src={"/uploads/posts/#{Enum.at(@images, 1).filename}"}
        alt="Image du post"
        class="rounded-lg h-24 w-full object-cover cursor-pointer hover:opacity-90 transition-opacity"
        phx-click="open_image_preview"
        phx-value-src={"/uploads/posts/#{Enum.at(@images, 1).filename}"}
      />
      <img
        src={"/uploads/posts/#{Enum.at(@images, 2).filename}"}
        alt="Image du post"
        class="rounded-lg h-24 w-full object-cover cursor-pointer hover:opacity-90 transition-opacity"
        phx-click="open_image_preview"
        phx-value-src={"/uploads/posts/#{Enum.at(@images, 2).filename}"}
      />
    </div>
    """
  end

  defp post_images(assigns) do
    extra_count = length(assigns.images) - 4
    assigns = assign(assigns, :extra_count, extra_count)

    ~H"""
    <div class="mt-3 grid grid-cols-2 gap-2">
      <%= for {image, index} <- Enum.take(@images, 4) |> Enum.with_index() do %>
        <div
          class="relative cursor-pointer"
          phx-click="open_image_preview"
          phx-value-src={"/uploads/posts/#{image.filename}"}
        >
          <img
            src={"/uploads/posts/#{image.filename}"}
            alt="Image du post"
            class="rounded-lg h-32 w-full object-cover hover:opacity-90 transition-opacity"
          />
          <!-- Overlay +X sur la 4ème image si plus de 4 images -->
          <div
            :if={index == 3 and @extra_count > 0}
            class="absolute inset-0 bg-black/60 rounded-lg flex items-center justify-center pointer-events-none"
          >
            <span class="text-white text-2xl font-bold">+{@extra_count}</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # ============== POST MENU ==============

  attr :post, :map, required: true

  defp post_menu(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-sm btn-circle">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
        </svg>
      </div>
      <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-40 p-2 shadow-lg border border-white/20">
        <li>
          <button phx-click="edit_post" phx-value-id={@post.id}>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            Modifier
          </button>
        </li>
        <li>
          <button
            phx-click="delete"
            phx-value-id={@post.id}
            data-confirm="Supprimer ce post ?"
            class="text-error"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
            Supprimer
          </button>
        </li>
      </ul>
    </div>
    """
  end

  # ============== USER AVATAR ==============

  attr :name, :string, required: true
  attr :size, :string, default: "w-10 h-10"

  def user_avatar(assigns) do
    ~H"""
    <div class={"#{@size} rounded-full bg-primary grid place-items-center"}>
      <span class="text-primary-content text-lg font-bold leading-none">
        {String.first(@name)}
      </span>
    </div>
    """
  end

  # ============== EMPTY STATE ==============

  defp empty_state(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body text-center text-base-content/50">
        Aucun post pour le moment. Soyez le premier à publier !
      </div>
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
