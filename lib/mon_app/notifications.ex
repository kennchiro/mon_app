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

  defp broadcast_notification(user_id, notification) do
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "user:#{user_id}",
      {:new_notification, notification}
    )
  end
end
