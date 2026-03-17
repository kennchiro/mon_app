defmodule MonApp.Social.UserReport do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.Post

  @user_reasons ["harassment", "spam", "fake_profile", "inappropriate_content", "underage", "other"]
  @post_reasons ["spam", "inappropriate_content", "misleading", "harassment", "scam", "other"]
  @date_reasons ["spam", "inappropriate_content", "misleading", "fake_date", "scam", "other"]

  schema "user_reports" do
    field :reason, :string
    field :details, :string
    field :status, :string, default: "pending"
    field :report_type, :string, default: "user"

    belongs_to :reporter, User
    belongs_to :reported, User
    belongs_to :post, Post
    timestamps()
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [:reporter_id, :reported_id, :reason, :details, :post_id, :report_type])
    |> validate_required([:reporter_id, :reason, :report_type])
    |> validate_inclusion(:report_type, ["user", "post", "date"])
  end

  def user_reasons, do: @user_reasons
  def post_reasons, do: @post_reasons
  def date_reasons, do: @date_reasons

  def reasons_for("date"), do: @date_reasons
  def reasons_for("post"), do: @post_reasons
  def reasons_for(_), do: @user_reasons

  # Labels français
  def reason_label("harassment"), do: "Harcèlement"
  def reason_label("spam"), do: "Spam"
  def reason_label("fake_profile"), do: "Faux profil"
  def reason_label("inappropriate_content"), do: "Contenu inapproprié"
  def reason_label("underage"), do: "Mineur"
  def reason_label("misleading"), do: "Trompeur / Mensonger"
  def reason_label("fake_date"), do: "Faux date / Arnaque"
  def reason_label("scam"), do: "Arnaque"
  def reason_label("other"), do: "Autre"
  def reason_label(_), do: "Autre"
end
