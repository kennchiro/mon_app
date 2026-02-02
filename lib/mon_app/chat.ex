defmodule MonApp.Chat do
  @moduledoc """
  Le context Chat - gère les conversations et messages.
  """

  import Ecto.Query
  alias MonApp.Repo
  alias MonApp.Chat.Conversation
  alias MonApp.Chat.ConversationParticipant
  alias MonApp.Chat.Message
  alias MonApp.Chat.MessageAttachment
  alias MonApp.Chat.MessageReaction
  alias MonApp.Social

  @messages_per_page 50
  @uploads_dir "priv/static/uploads/chat"

  # ============== CONVERSATIONS 1-à-1 ==============

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
    |> where([c], c.is_group == false)
    |> preload([:user1, :user2])
    |> Repo.one()
  end

  @doc "Récupère une conversation par ID"
  def get_conversation(id) do
    Conversation
    |> Repo.get(id)
    |> Repo.preload([:user1, :user2, :admin, participants: :user])
  end

  @doc "Crée une nouvelle conversation 1-à-1"
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

  # ============== CONVERSATIONS DE GROUPE ==============

  @doc """
  Crée une conversation de groupe avec les participants spécifiés.
  Vérifie que le créateur est ami avec tous les participants.
  """
  def create_group_conversation(admin_id, participant_ids, name) when is_list(participant_ids) do
    # S'assurer que l'admin est inclus dans les participants
    all_participant_ids = Enum.uniq([admin_id | participant_ids])

    # Vérifier que l'admin est ami avec tous les autres participants
    non_friends =
      participant_ids
      |> Enum.reject(&(&1 == admin_id))
      |> Enum.reject(fn id -> Social.friendship_status(admin_id, id) == :friends end)

    if non_friends != [] do
      {:error, :not_friends_with_all}
    else
      Repo.transaction(fn ->
        # Créer la conversation de groupe
        {:ok, conversation} =
          %Conversation{}
          |> Conversation.group_changeset(%{name: name, admin_id: admin_id})
          |> Repo.insert()

        # Ajouter tous les participants
        Enum.each(all_participant_ids, fn user_id ->
          %ConversationParticipant{}
          |> ConversationParticipant.changeset(%{
            conversation_id: conversation.id,
            user_id: user_id
          })
          |> Repo.insert!()
        end)

        # Retourner la conversation avec les preloads
        Repo.preload(conversation, [:admin, participants: :user])
      end)
    end
  end

  @doc "Ajoute un participant à un groupe"
  def add_participant(conversation_id, user_id, added_by_id) do
    conversation = get_conversation(conversation_id)

    cond do
      conversation == nil ->
        {:error, :conversation_not_found}

      not conversation.is_group ->
        {:error, :not_a_group}

      conversation.admin_id != added_by_id ->
        {:error, :not_admin}

      Social.friendship_status(added_by_id, user_id) != :friends ->
        {:error, :not_friends}

      true ->
        %ConversationParticipant{}
        |> ConversationParticipant.changeset(%{
          conversation_id: conversation_id,
          user_id: user_id
        })
        |> Repo.insert()
    end
  end

  @doc "Retire un participant d'un groupe"
  def remove_participant(conversation_id, user_id, removed_by_id) do
    conversation = get_conversation(conversation_id)

    cond do
      conversation == nil ->
        {:error, :conversation_not_found}

      not conversation.is_group ->
        {:error, :not_a_group}

      # Seul l'admin peut retirer quelqu'un, ou on peut se retirer soi-même
      conversation.admin_id != removed_by_id && user_id != removed_by_id ->
        {:error, :not_allowed}

      # L'admin ne peut pas se retirer (doit transférer l'admin d'abord)
      user_id == conversation.admin_id ->
        {:error, :admin_cannot_leave}

      true ->
        ConversationParticipant
        |> where(conversation_id: ^conversation_id, user_id: ^user_id)
        |> Repo.delete_all()

        {:ok, :removed}
    end
  end

  @doc "Liste les participants d'une conversation de groupe"
  def list_participants(conversation_id) do
    ConversationParticipant
    |> where(conversation_id: ^conversation_id)
    |> preload(:user)
    |> Repo.all()
    |> Enum.map(& &1.user)
  end

  @doc """
  Liste les conversations d'un utilisateur avec le dernier message et le compteur non-lus.
  Triées par dernier message.
  """
  def list_conversations(user_id) do
    # Conversations 1-à-1
    direct_conversations =
      Conversation
      |> where([c], (c.user1_id == ^user_id or c.user2_id == ^user_id) and c.is_group == false)
      |> preload([:user1, :user2])
      |> Repo.all()

    # Conversations de groupe
    group_conversation_ids =
      ConversationParticipant
      |> where(user_id: ^user_id)
      |> select([p], p.conversation_id)
      |> Repo.all()

    group_conversations =
      if group_conversation_ids == [] do
        []
      else
        Conversation
        |> where([c], c.id in ^group_conversation_ids and c.is_group == true)
        |> preload([:admin, participants: :user])
        |> Repo.all()
      end

    # Combiner et enrichir toutes les conversations
    (direct_conversations ++ group_conversations)
    |> Enum.map(fn conv ->
      last_message = get_last_message(conv.id)
      unread_count = count_unread_messages(conv.id, user_id)

      conv
      |> Map.put(:last_message, last_message)
      |> Map.put(:unread_count, unread_count)
    end)
    |> Enum.sort_by(
      fn conv ->
        conv.last_message_at || conv.updated_at
      end,
      {:desc, NaiveDateTime}
    )
  end

  @doc "Vérifie si un utilisateur fait partie d'une conversation"
  def user_in_conversation?(conversation_id, user_id) do
    conversation = Repo.get(Conversation, conversation_id)

    if conversation == nil do
      false
    else
      if conversation.is_group do
        # Pour les groupes, vérifier dans la table participants
        ConversationParticipant
        |> where(conversation_id: ^conversation_id, user_id: ^user_id)
        |> Repo.exists?()
      else
        # Pour les 1-à-1, vérifier user1 ou user2
        conversation.user1_id == user_id || conversation.user2_id == user_id
      end
    end
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
        {:ok, Repo.preload(message, [:sender, :attachments])}

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
      |> preload([:sender, :attachments])

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
    |> preload([:sender, :attachments])
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
    # Récupérer les IDs des conversations 1-à-1 de l'utilisateur
    direct_conversation_ids =
      Conversation
      |> where([c], (c.user1_id == ^user_id or c.user2_id == ^user_id) and c.is_group == false)
      |> select([c], c.id)
      |> Repo.all()

    # Récupérer les IDs des conversations de groupe
    group_conversation_ids =
      ConversationParticipant
      |> where(user_id: ^user_id)
      |> select([p], p.conversation_id)
      |> Repo.all()

    conversation_ids = direct_conversation_ids ++ group_conversation_ids

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

  # ============== MESSAGE ATTACHMENTS ==============

  @doc "Retourne le répertoire des uploads chat"
  def uploads_dir, do: @uploads_dir

  @doc "Crée un attachement pour un message"
  def create_message_attachment(attrs) do
    %MessageAttachment{}
    |> MessageAttachment.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Récupère un attachement par ID"
  def get_message_attachment(id) do
    Repo.get(MessageAttachment, id)
    |> Repo.preload(:message)
  end

  @doc "Supprime un attachement et son fichier"
  def delete_message_attachment(%MessageAttachment{} = attachment) do
    # Supprimer le fichier physique
    file_path = Path.join(@uploads_dir, attachment.filename)
    File.rm(file_path)

    # Supprimer de la base de données
    Repo.delete(attachment)
  end

  @doc "Supprime tous les attachements d'un message"
  def delete_message_attachments(message_id) do
    attachments =
      MessageAttachment
      |> where(message_id: ^message_id)
      |> Repo.all()

    Enum.each(attachments, fn attachment ->
      file_path = Path.join(@uploads_dir, attachment.filename)
      File.rm(file_path)
    end)

    MessageAttachment
    |> where(message_id: ^message_id)
    |> Repo.delete_all()
  end

  @doc "Récupère un message par ID avec ses attachements et réactions"
  def get_message(id) do
    Message
    |> Repo.get(id)
    |> Repo.preload([:sender, :attachments, reactions: :user])
  end

  @doc "Supprime un message et ses attachements"
  def delete_message(%Message{} = message) do
    # Supprimer les fichiers physiques des attachements
    message = Repo.preload(message, :attachments)

    Enum.each(message.attachments, fn attachment ->
      file_path = Path.join(@uploads_dir, attachment.filename)
      File.rm(file_path)
    end)

    # Supprimer le message (les attachements seront supprimés en cascade)
    Repo.delete(message)
  end

  # ============== SOFT DELETE ==============

  @doc "Supprime un message pour l'expéditeur uniquement"
  def delete_message_for_me(message_id, user_id) do
    message = Repo.get(Message, message_id)

    cond do
      message == nil ->
        {:error, :not_found}

      message.sender_id != user_id ->
        {:error, :unauthorized}

      true ->
        message
        |> Message.delete_changeset(:for_me)
        |> Repo.update()
    end
  end

  @doc "Supprime un message pour tous les participants"
  def delete_message_for_all(message_id, user_id) do
    message = Repo.get(Message, message_id)

    cond do
      message == nil ->
        {:error, :not_found}

      message.sender_id != user_id ->
        {:error, :unauthorized}

      message.deleted_for_all_at != nil ->
        {:error, :already_deleted}

      true ->
        result =
          message
          |> Message.delete_changeset(:for_all)
          |> Repo.update()

        case result do
          {:ok, updated_message} ->
            # Précharger les associations pour éviter les erreurs de rendu
            updated_message = Repo.preload(updated_message, [:sender, :attachments, reply_to: :sender, reactions: :user])
            # Broadcast to all participants
            broadcast_message_deleted(updated_message)
            {:ok, updated_message}

          error ->
            error
        end
    end
  end

  defp broadcast_message_deleted(message) do
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "chat:#{message.conversation_id}",
      {:message_deleted, %{id: message.id, deleted_for_all_at: message.deleted_for_all_at, sender_id: message.sender_id}}
    )
  end

  # ============== REPLY TO MESSAGE ==============

  @doc "Récupère un message avec le message de réponse et réactions préchargés"
  def get_message_with_reply(id) do
    Message
    |> Repo.get(id)
    |> Repo.preload([:sender, :attachments, reply_to: :sender, reactions: :user])
  end

  @doc "Récupère les messages avec les réponses et réactions préchargées"
  def list_messages_with_replies(conversation_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, @messages_per_page)
    before_id = Keyword.get(opts, :before_id)
    user_id = Keyword.get(opts, :user_id)

    query =
      Message
      |> where(conversation_id: ^conversation_id)
      |> order_by(desc: :inserted_at)
      |> limit(^limit)
      |> preload([:sender, :attachments, reply_to: :sender, reactions: :user])

    query =
      if before_id do
        where(query, [m], m.id < ^before_id)
      else
        query
      end

    query
    |> Repo.all()
    |> Enum.reverse()
    |> filter_deleted_messages(user_id)
  end

  defp filter_deleted_messages(messages, nil), do: messages
  defp filter_deleted_messages(messages, user_id) do
    Enum.filter(messages, fn msg ->
      Message.visible_for?(msg, user_id)
    end)
  end

  # ============== MESSAGE REACTIONS ==============

  @doc "Ajoute ou retire une réaction à un message (toggle)"
  def toggle_reaction(message_id, user_id, emoji) do
    case get_reaction(message_id, user_id, emoji) do
      nil ->
        add_reaction(message_id, user_id, emoji)

      reaction ->
        remove_reaction(reaction)
    end
  end

  @doc "Ajoute une réaction à un message"
  def add_reaction(message_id, user_id, emoji) do
    message = Repo.get(Message, message_id)

    if message == nil do
      {:error, :message_not_found}
    else
      result =
        %MessageReaction{}
        |> MessageReaction.changeset(%{
          message_id: message_id,
          user_id: user_id,
          emoji: emoji
        })
        |> Repo.insert()

      case result do
        {:ok, reaction} ->
          reaction = Repo.preload(reaction, :user)
          broadcast_reaction_added(message.conversation_id, message_id, reaction)
          {:ok, reaction}

        {:error, %Ecto.Changeset{errors: [message_id_user_id_emoji: _]}} ->
          # La réaction existe déjà
          {:error, :already_exists}

        error ->
          error
      end
    end
  end

  @doc "Retire une réaction"
  def remove_reaction(%MessageReaction{} = reaction) do
    message = Repo.get(Message, reaction.message_id)

    case Repo.delete(reaction) do
      {:ok, _} ->
        if message do
          broadcast_reaction_removed(message.conversation_id, reaction.message_id, reaction)
        end
        {:ok, :removed}

      error ->
        error
    end
  end

  @doc "Retire une réaction par ses identifiants"
  def remove_reaction(message_id, user_id, emoji) do
    case get_reaction(message_id, user_id, emoji) do
      nil ->
        {:error, :not_found}

      reaction ->
        remove_reaction(reaction)
    end
  end

  @doc "Récupère une réaction spécifique"
  def get_reaction(message_id, user_id, emoji) do
    MessageReaction
    |> where(message_id: ^message_id, user_id: ^user_id, emoji: ^emoji)
    |> Repo.one()
  end

  @doc "Liste toutes les réactions d'un message"
  def list_reactions(message_id) do
    MessageReaction
    |> where(message_id: ^message_id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc "Liste les réactions d'un message groupées par emoji"
  def list_reactions_grouped(message_id) do
    reactions = list_reactions(message_id)

    reactions
    |> Enum.group_by(& &1.emoji)
    |> Enum.map(fn {emoji, reactions} ->
      %{
        emoji: emoji,
        count: length(reactions),
        users: Enum.map(reactions, & &1.user),
        user_ids: Enum.map(reactions, & &1.user_id)
      }
    end)
    |> Enum.sort_by(& &1.count, :desc)
  end

  @doc "Vérifie si un utilisateur a réagi avec un emoji donné"
  def user_reacted?(message_id, user_id, emoji) do
    MessageReaction
    |> where(message_id: ^message_id, user_id: ^user_id, emoji: ^emoji)
    |> Repo.exists?()
  end

  @doc "Récupère les messages avec leurs réactions"
  def list_messages_with_reactions(conversation_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, @messages_per_page)
    before_id = Keyword.get(opts, :before_id)
    user_id = Keyword.get(opts, :user_id)

    query =
      Message
      |> where(conversation_id: ^conversation_id)
      |> order_by(desc: :inserted_at)
      |> limit(^limit)
      |> preload([:sender, :attachments, reply_to: :sender, reactions: :user])

    query =
      if before_id do
        where(query, [m], m.id < ^before_id)
      else
        query
      end

    query
    |> Repo.all()
    |> Enum.reverse()
    |> filter_deleted_messages(user_id)
  end

  defp broadcast_reaction_added(conversation_id, message_id, reaction) do
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "chat:#{conversation_id}",
      {:reaction_added, message_id, reaction}
    )
  end

  defp broadcast_reaction_removed(conversation_id, message_id, reaction) do
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "chat:#{conversation_id}",
      {:reaction_removed, message_id, reaction}
    )
  end
end
