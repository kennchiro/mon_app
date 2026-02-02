defmodule MonAppWeb.TimeHelpers do
  @moduledoc """
  Helpers pour l'affichage du temps relatif (time ago).
  """

  @doc """
  Convertit une date en format "il y a X temps".

  ## Examples

      iex> time_ago(~N[2024-01-01 12:00:00])
      "il y a 3 mois"

  """
  def time_ago(datetime) when is_struct(datetime, NaiveDateTime) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.diff(datetime, :second)
    |> format_diff()
  end

  def time_ago(datetime) when is_struct(datetime, DateTime) do
    datetime
    |> DateTime.to_naive()
    |> time_ago()
  end

  def time_ago(_), do: ""

  defp format_diff(seconds) when seconds < 0, do: "dans le futur"
  defp format_diff(seconds) when seconds < 5, do: "à l'instant"
  defp format_diff(seconds) when seconds < 60, do: "il y a #{seconds} sec"
  defp format_diff(seconds) when seconds < 120, do: "il y a 1 min"
  defp format_diff(seconds) when seconds < 3600 do
    minutes = div(seconds, 60)
    "il y a #{minutes} min"
  end
  defp format_diff(seconds) when seconds < 7200, do: "il y a 1 h"
  defp format_diff(seconds) when seconds < 86400 do
    hours = div(seconds, 3600)
    "il y a #{hours} h"
  end
  defp format_diff(seconds) when seconds < 172800, do: "il y a 1 jour"
  defp format_diff(seconds) when seconds < 604800 do
    days = div(seconds, 86400)
    "il y a #{days} jours"
  end
  defp format_diff(seconds) when seconds < 1209600, do: "il y a 1 semaine"
  defp format_diff(seconds) when seconds < 2592000 do
    weeks = div(seconds, 604800)
    "il y a #{weeks} semaines"
  end
  defp format_diff(seconds) when seconds < 5184000, do: "il y a 1 mois"
  defp format_diff(seconds) when seconds < 31536000 do
    months = div(seconds, 2592000)
    "il y a #{months} mois"
  end
  defp format_diff(seconds) when seconds < 63072000, do: "il y a 1 an"
  defp format_diff(seconds) do
    years = div(seconds, 31536000)
    "il y a #{years} ans"
  end
end
