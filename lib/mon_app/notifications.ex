defmodule MonApp.Notifications do
  import Ecto.Query

  alias MonApp.Repo
  alias MonApp.Notifications.Notification

  @max_notifications 50

  def list_notifications(user_id, limit \\ @max_notifications) do
    Notification
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload([:actor, :post])
    |> Repo.all()
  end

  def count_unread(user_id) do
    Notification
    |> where(user_id: ^user_id, read: false)
    |> Repo.aggregate(:count)
  end

  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  def mark_as_read(notification_id, user_id) do
    Notification
    |> where(id: ^notification_id, user_id: ^user_id)
    |> Repo.update_all(set: [read: true])
  end

  def mark_all_as_read(user_id) do
    Notification
    |> where(user_id: ^user_id, read: false)
    |> Repo.update_all(set: [read: true])
  end

  def notify_comment(post, comment, commenter) do
    if post.user_id != commenter.id do
      message = "#{commenter.name} a commenté ton post"

      case create_notification(%{
             type: "comment",
             message: message,
             user_id: post.user_id,
             actor_id: commenter.id,
             post_id: post.id,
             comment_id: comment.id
           }) do
        {:ok, notification} ->
          notification = Repo.preload(notification, [:actor, :post])
          broadcast_notification(post.user_id, notification)
          {:ok, notification}

        error ->
          error
      end
    else
      {:ok, :self}
    end
  end

  def notify_reply(post, reply, parent_comment, replier) do
    # Notifier l'auteur du commentaire parent (pas soi-même)
    if parent_comment.user_id != replier.id do
      message = "#{replier.name} a répondu à ton commentaire"

      case create_notification(%{
             type: "reply",
             message: message,
             user_id: parent_comment.user_id,
             actor_id: replier.id,
             post_id: post.id,
             comment_id: reply.id
           }) do
        {:ok, notification} ->
          notification = Repo.preload(notification, [:actor, :post])
          broadcast_notification(parent_comment.user_id, notification)
          {:ok, notification}

        error ->
          error
      end
    else
      {:ok, :self}
    end
  end

  def notify_date_application(post, applicant) do
    if post.user_id != applicant.id do
      message = "#{applicant.name} est intéressé(e) par ton date « #{post.date_title} »"

      case create_notification(%{
             type: "date_application",
             message: message,
             user_id: post.user_id,
             actor_id: applicant.id,
             post_id: post.id
           }) do
        {:ok, notification} ->
          notification = Repo.preload(notification, [:actor, :post])
          broadcast_notification(post.user_id, notification)
          {:ok, notification}

        error ->
          error
      end
    else
      {:ok, :self}
    end
  end

  def notify_date_accepted(post, applicant_id) do
    applicant = MonApp.Accounts.get_user(applicant_id)
    owner = MonApp.Accounts.get_user(post.user_id)
    if applicant && owner do
      message = "#{owner.name} a accepté ta candidature pour « #{post.date_title} » 🎉"

      case create_notification(%{
             type: "date_accepted",
             message: message,
             user_id: applicant_id,
             actor_id: post.user_id,
             post_id: post.id
           }) do
        {:ok, notification} ->
          notification = Repo.preload(notification, [:actor, :post])
          broadcast_notification(applicant_id, notification)
          {:ok, notification}

        error ->
          error
      end
    else
      {:ok, :not_found}
    end
  end

  def notify_friend_request(sender, receiver_id) do
    if sender.id != receiver_id do
      message = "#{sender.name} vous a envoyé une demande d'ami"

      case create_notification(%{
             type: "friend_request",
             message: message,
             user_id: receiver_id,
             actor_id: sender.id
           }) do
        {:ok, notification} ->
          notification = Repo.preload(notification, [:actor, :post])
          broadcast_notification(receiver_id, notification)
          {:ok, notification}

        error ->
          error
      end
    else
      {:ok, :self}
    end
  end

  def notify_friend_accepted(accepter, sender_id) do
    if accepter.id != sender_id do
      message = "#{accepter.name} a accepté votre demande d'ami"

      case create_notification(%{
             type: "friend_accepted",
             message: message,
             user_id: sender_id,
             actor_id: accepter.id
           }) do
        {:ok, notification} ->
          notification = Repo.preload(notification, [:actor, :post])
          broadcast_notification(sender_id, notification)
          {:ok, notification}

        error ->
          error
      end
    else
      {:ok, :self}
    end
  end

  defp broadcast_notification(user_id, notification) do
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "user:#{user_id}",
      {:new_notification, notification}
    )
  end
end
