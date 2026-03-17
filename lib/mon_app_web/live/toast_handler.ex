defmodule MonAppWeb.ToastHandler do
  @moduledoc "Shared toast logic for LiveViews"

  import Phoenix.Component, only: [assign: 3]
  alias MonAppWeb.Toast

  def init_toast(socket) do
    assign(socket, :toast, nil)
  end

  def show_notification_toast(socket, notification) do
    toast = Toast.toast_from_notification(notification)
    schedule_dismiss()
    assign(socket, :toast, toast)
  end

  def show_message_toast(socket, message, sender_name, sender_avatar) do
    toast = Toast.toast_from_message(message, sender_name, sender_avatar)
    schedule_dismiss()
    assign(socket, :toast, toast)
  end

  def dismiss_toast(socket) do
    if socket.assigns[:toast] do
      assign(socket, :toast, %{socket.assigns.toast | exiting: true})
    else
      socket
    end
  end

  def clear_toast(socket) do
    assign(socket, :toast, nil)
  end

  defp schedule_dismiss do
    Process.send_after(self(), :auto_dismiss_toast, 5000)
  end
end
