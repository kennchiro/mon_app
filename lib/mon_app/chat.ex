defmodule MonApp.Chat do
  @moduledoc """
  Le context Chat - gère les conversations et messages.
  """

  import Ecto.Query
  alias MonApp.Repo
  alias MonApp.Chat.Conversation
  alias MonApp.Chat.Message
  alias MonApp.Social

  @messages_per_page 50

  # ============== CONVERSATIONS ==============

  @doc """
  Récupère ou crée une conversation entre deux utilisateurs.
  Vérifie d'abord qu'ils sont amis.
  """
  def get_or_create_conversation(user1_id, user2_id) do
    # Vérifier qu'ils sont amis
    unless Social.friendship_status(user1_id, user2_id) == :friends do
      {:error, :not_friends}
    else
      # Normaliser l'ordre des IDs
      {min_id, max_id} = if user1_id < user2_id, do: {user1_id, user2_id}, else: {user2_id, user1_id}

      case get_conversation_by_users(min_id, max_id) do
        nil ->
          create_conversation(%{user1_id: min_id, user2_id: max_id})

        conversation ->
          {:ok, conversation}
      end
    end
  end

  @doc "Récupère une conversation par les IDs des deux users"
  def get_conversation_by_users(user1_id, user2_id) do
    # Normaliser l'ordre
    {min_id, max_id} = if user1_id < user2_id, do: {user1_id, user2_id}, else: {user2_id, user1_id}

    Conversation
    |> where(user1_id: ^min_id, user2_id: ^max_id)
    |> preload([:user1, :user2])
    |> Repo.one()
  end

  @doc "Récupère une conversation par ID"
  def get_conversation(id) do
    Conversation
    |> Repo.get(id)
    |> Repo.preload([:user1, :user2])
  end

  @doc "Crée une nouvelle conversation"
  def create_conversation(attrs) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, conversation} ->
        {:ok, Repo.preload(conversation, [:user1, :user2])}

      error ->
        error
    end
  end

  @doc """
  Liste les conversations d'un utilisateur avec le dernier message et le compteur non-lus.
  Triées par dernier message.
  """
  def list_conversations(user_id) do
    Conversation
    |> where([c], c.user1_id == ^user_id or c.user2_id == ^user_id)
    |> order_by([c], desc: c.last_message_at, desc: c.updated_at)
    |> preload([:user1, :user2])
    |> Repo.all()
    |> Enum.map(fn conv ->
      last_message = get_last_message(conv.id)
      unread_count = count_unread_messages(conv.id, user_id)

      conv
      |> Map.put(:last_message, last_message)
      |> Map.put(:unread_count, unread_count)
    end)
  end

  @doc "Vérifie si un utilisateur fait partie d'une conversation"
  def user_in_conversation?(conversation_id, user_id) do
    Conversation
    |> where([c], c.id == ^conversation_id)
    |> where([c], c.user1_id == ^user_id or c.user2_id == ^user_id)
    |> Repo.exists?()
  end

  # ============== MESSAGES ==============

  @doc "Crée un message dans une conversation"
  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        # Mettre à jour last_message_at de la conversation
        update_conversation_last_message(message.conversation_id)
        {:ok, Repo.preload(message, :sender)}

      error ->
        error
    end
  end

  @doc "Récupère les messages d'une conversation (paginé)"
  def list_messages(conversation_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, @messages_per_page)
    before_id = Keyword.get(opts, :before_id)

    query =
      Message
      |> where(conversation_id: ^conversation_id)
      |> order_by(desc: :inserted_at)
      |> limit(^limit)
      |> preload(:sender)

    query =
      if before_id do
        where(query, [m], m.id < ^before_id)
      else
        query
      end

    query
    |> Repo.all()
    |> Enum.reverse()  # Pour avoir l'ordre chronologique
  end

  @doc "Récupère le dernier message d'une conversation"
  def get_last_message(conversation_id) do
    Message
    |> where(conversation_id: ^conversation_id)
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> preload(:sender)
    |> Repo.one()
  end

  @doc "Compte les messages non lus pour un utilisateur dans une conversation"
  def count_unread_messages(conversation_id, user_id) do
    Message
    |> where(conversation_id: ^conversation_id)
    |> where([m], m.sender_id != ^user_id)
    |> where([m], m.status != "seen")
    |> Repo.aggregate(:count)
  end

  @doc "Compte le total des messages non lus pour un utilisateur"
  def count_total_unread(user_id) do
    # Récupérer les IDs des conversations de l'utilisateur
    conversation_ids =
      Conversation
      |> where([c], c.user1_id == ^user_id or c.user2_id == ^user_id)
      |> select([c], c.id)
      |> Repo.all()

    if conversation_ids == [] do
      0
    else
      Message
      |> where([m], m.conversation_id in ^conversation_ids)
      |> where([m], m.sender_id != ^user_id)
      |> where([m], m.status != "seen")
      |> Repo.aggregate(:count)
    end
  end

  # ============== MESSAGE STATUS (ACK) ==============

  @doc """
  Marque un message comme délivré.
  Appelé quand le destinataire est connecté et reçoit le message.
  """
  def mark_as_delivered(message_id) do
    message = Repo.get(Message, message_id)

    if message && message.status == "sent" do
      message
      |> Message.status_changeset(%{
        status: "delivered",
        delivered_at: DateTime.utc_now()
      })
      |> Repo.update()
    else
      {:ok, message}
    end
  end

  @doc """
  Marque plusieurs messages comme délivrés.
  """
  def mark_messages_as_delivered(message_ids) when is_list(message_ids) do
    now = DateTime.utc_now()

    Message
    |> where([m], m.id in ^message_ids)
    |> where([m], m.status == "sent")
    |> Repo.update_all(set: [status: "delivered", delivered_at: now])
  end

  @doc """
  Marque tous les messages d'une conversation comme vus.
  Appelé quand l'utilisateur ouvre la conversation.
  """
  def mark_conversation_as_seen(conversation_id, user_id) do
    now = DateTime.utc_now()

    # Seulement les messages non envoyés par l'utilisateur
    {count, _} =
      Message
      |> where(conversation_id: ^conversation_id)
      |> where([m], m.sender_id != ^user_id)
      |> where([m], m.status != "seen")
      |> Repo.update_all(set: [status: "seen", seen_at: now])

    {:ok, count}
  end

  @doc """
  Récupère les IDs des messages qui ont changé de statut.
  Utilisé pour notifier l'expéditeur.
  """
  def get_messages_to_ack(conversation_id, user_id, status) do
    Message
    |> where(conversation_id: ^conversation_id)
    |> where([m], m.sender_id == ^user_id)
    |> where([m], m.status == ^status)
    |> select([m], m.id)
    |> Repo.all()
  end

  # ============== HELPERS ==============

  defp update_conversation_last_message(conversation_id) do
    Conversation
    |> where(id: ^conversation_id)
    |> Repo.update_all(set: [last_message_at: DateTime.utc_now()])
  end

  @doc "Retourne l'autre utilisateur dans une conversation"
  def get_other_user(conversation, current_user_id) do
    Conversation.other_user(conversation, current_user_id)
  end

  @doc "Vérifie si deux utilisateurs peuvent chatter (sont amis)"
  def can_chat?(user1_id, user2_id) do
    Social.friendship_status(user1_id, user2_id) == :friends
  end
end
