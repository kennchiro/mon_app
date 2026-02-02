defmodule MonAppWeb.ChatChannel do
  @moduledoc """
  Channel pour une conversation spécifique.
  Gère l'envoi et la réception des messages en temps réel.
  """

  use Phoenix.Channel

  import Ecto.Query

  alias MonApp.Chat
  alias MonApp.Repo
  alias MonAppWeb.Presence

  @impl true
  def join("chat:" <> conversation_id, _params, socket) do
    conversation_id = String.to_integer(conversation_id)
    user_id = socket.assigns.current_user.id

    # Vérifier que l'utilisateur fait partie de la conversation
    if Chat.user_in_conversation?(conversation_id, user_id) do
      conversation = Chat.get_conversation(conversation_id)
      send(self(), :after_join)

      {:ok, assign(socket, :conversation, conversation)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    user = socket.assigns.current_user

    # Tracker la présence dans cette conversation
    {:ok, _} = Presence.track(socket, to_string(user.id), %{
      user_id: user.id,
      name: user.name,
      typing: false
    })

    # Pousser la liste des présences actuelles
    push(socket, "presence_state", Presence.list(socket))

    # Marquer les messages comme vus
    mark_messages_as_seen(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_in("new_message", %{"body" => body}, socket) do
    user = socket.assigns.current_user
    conversation = socket.assigns.conversation
    other_user_id = Chat.get_other_user(conversation, user.id) |> Map.get(:id)

    case Chat.create_message(%{
      body: body,
      conversation_id: conversation.id,
      sender_id: user.id
    }) do
      {:ok, message} ->
        # Diffuser le message à tous les participants du channel
        broadcast!(socket, "new_message", %{
          id: message.id,
          body: message.body,
          sender_id: message.sender_id,
          sender_name: message.sender.name,
          status: message.status,
          inserted_at: message.inserted_at
        })

        # Notifier l'autre utilisateur via son channel personnel
        Phoenix.PubSub.broadcast(
          MonApp.PubSub,
          "user:#{other_user_id}",
          {:new_message, message}
        )

        # Répondre avec l'ACK "sent"
        {:reply, {:ok, %{id: message.id, status: "sent"}}, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{reason: "could not send message"}}, socket}
    end
  end

  @impl true
  def handle_in("typing", %{"typing" => typing}, socket) do
    user = socket.assigns.current_user

    # Mettre à jour la présence avec le statut de frappe
    Presence.update(socket, to_string(user.id), fn meta ->
      Map.put(meta, :typing, typing)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_in("mark_seen", _params, socket) do
    mark_messages_as_seen(socket)
    {:reply, :ok, socket}
  end

  # Marquer les messages de l'autre utilisateur comme vus
  defp mark_messages_as_seen(socket) do
    user_id = socket.assigns.current_user.id
    conversation = socket.assigns.conversation
    conversation_id = conversation.id
    other_user_id = Chat.get_other_user(conversation, user_id) |> Map.get(:id)

    # Récupérer les messages à marquer comme vus
    messages_to_mark =
      MonApp.Chat.Message
      |> where([m], m.conversation_id == ^conversation_id)
      |> where([m], m.sender_id == ^other_user_id)
      |> where([m], m.status != "seen")
      |> select([m], m.id)
      |> Repo.all()

    if messages_to_mark != [] do
      Chat.mark_conversation_as_seen(conversation_id, user_id)

      # Notifier l'expéditeur que ses messages ont été vus
      Phoenix.PubSub.broadcast(
        MonApp.PubSub,
        "user:#{other_user_id}",
        {:messages_seen, messages_to_mark}
      )
    end
  end

  @impl true
  def terminate(_reason, _socket) do
    # Nettoyer la présence
    :ok
  end
end
