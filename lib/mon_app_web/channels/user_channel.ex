defmodule MonAppWeb.UserChannel do
  @moduledoc """
  Channel personnel pour chaque utilisateur.
  Utilisé pour:
  - Notifications de nouveaux messages
  - Mise à jour des ACK (delivered/seen)
  - Présence online
  """

  use Phoenix.Channel

  import Ecto.Query

  alias MonAppWeb.Presence
  alias MonApp.Chat
  alias MonApp.Repo

  @impl true
  def join("user:" <> user_id, _params, socket) do
    # Vérifier que l'utilisateur rejoint son propre channel
    if String.to_integer(user_id) == socket.assigns.current_user.id do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    user = socket.assigns.current_user

    # Tracker la présence de l'utilisateur
    {:ok, _} = Presence.track(socket, to_string(user.id), %{
      user_id: user.id,
      name: user.name,
      online_at: System.system_time(:second)
    })

    # Tracker aussi sur le topic global pour la liste des utilisateurs en ligne
    {:ok, _} = Presence.track(self(), "users:online", to_string(user.id), %{
      user_id: user.id,
      name: user.name,
      online_at: System.system_time(:second)
    })

    # Envoyer les messages non délivrés en attente
    deliver_pending_messages(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # Notifier l'utilisateur d'un nouveau message
    push(socket, "new_message", %{
      id: message.id,
      conversation_id: message.conversation_id,
      sender_id: message.sender_id,
      sender_name: message.sender.name,
      body: message.body,
      inserted_at: message.inserted_at
    })

    # Marquer comme délivré
    Chat.mark_as_delivered(message.id)

    # Notifier l'expéditeur que le message a été délivré
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "user:#{message.sender_id}",
      {:message_delivered, message.id}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_delivered, message_id}, socket) do
    push(socket, "message_delivered", %{message_id: message_id})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_seen, message_id}, socket) do
    push(socket, "message_seen", %{message_id: message_id})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:messages_seen, message_ids}, socket) do
    push(socket, "messages_seen", %{message_ids: message_ids})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:messages_delivered, message_ids}, socket) do
    push(socket, "messages_delivered", %{message_ids: message_ids})
    {:noreply, socket}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # Délivrer les messages en attente quand l'utilisateur se connecte
  defp deliver_pending_messages(socket) do
    user_id = socket.assigns.current_user.id

    # Récupérer les conversations de l'utilisateur
    conversations = Chat.list_conversations(user_id)

    # Pour chaque conversation, marquer les messages non-délivrés comme délivrés
    Enum.each(conversations, fn conv ->
      # Récupérer les messages envoyés par l'autre personne qui sont en "sent"
      other_user_id = Chat.get_other_user(conv, user_id) |> Map.get(:id)
      conv_id = conv.id

      pending_messages =
        MonApp.Chat.Message
        |> where([m], m.conversation_id == ^conv_id)
        |> where([m], m.sender_id == ^other_user_id)
        |> where([m], m.status == "sent")
        |> Repo.all()

      if pending_messages != [] do
        message_ids = Enum.map(pending_messages, & &1.id)
        Chat.mark_messages_as_delivered(message_ids)

        # Notifier l'expéditeur
        Phoenix.PubSub.broadcast(
          MonApp.PubSub,
          "user:#{other_user_id}",
          {:messages_delivered, message_ids}
        )
      end
    end)
  end
end
