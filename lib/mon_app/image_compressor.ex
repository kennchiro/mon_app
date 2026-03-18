defmodule MonApp.ImageCompressor do
  @moduledoc """
  Compresses uploaded images to reduce storage and bandwidth.
  Uses system tools (sips on macOS, convert on Linux).
  """

  @max_dimension 1200
  @quality 85

  @doc """
  Compresses an image file in-place.
  Resizes to max 1200px on longest side and compresses to 85% quality.
  Returns :ok or {:error, reason}.
  """
  def compress(file_path) do
    ext = Path.extname(file_path) |> String.downcase()

    if ext in [".jpg", ".jpeg", ".png", ".webp"] do
      cond do
        System.find_executable("convert") ->
          compress_with_imagemagick(file_path)

        System.find_executable("sips") ->
          compress_with_sips(file_path)

        true ->
          # No tool available, skip compression
          :ok
      end
    else
      :ok
    end
  end

  @doc """
  Compresses an avatar (smaller: max 400px).
  """
  def compress_avatar(file_path) do
    ext = Path.extname(file_path) |> String.downcase()

    if ext in [".jpg", ".jpeg", ".png", ".webp"] do
      cond do
        System.find_executable("convert") ->
          run_command("convert", [file_path, "-resize", "400x400>", "-quality", "80", file_path])

        System.find_executable("sips") ->
          run_command("sips", ["--resampleHeightWidthMax", "400", "-s", "formatOptions", "80", file_path])

        true ->
          :ok
      end
    else
      :ok
    end
  end

  defp compress_with_imagemagick(file_path) do
    run_command("convert", [
      file_path,
      "-resize", "#{@max_dimension}x#{@max_dimension}>",
      "-quality", to_string(@quality),
      "-strip",
      file_path
    ])
  end

  defp compress_with_sips(file_path) do
    run_command("sips", [
      "--resampleHeightWidthMax", to_string(@max_dimension),
      "-s", "formatOptions", to_string(@quality),
      file_path
    ])
  end

  defp run_command(cmd, args) do
    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {_, 0} -> :ok
      {output, _} -> {:error, output}
    end
  end
end
