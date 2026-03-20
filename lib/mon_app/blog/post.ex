defmodule MonApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.PostImage
  alias MonApp.Blog.Comment
  alias MonApp.Blog.Reaction
  alias MonApp.Blog.DateApplication

  @visibility_options ["public", "friends", "private"]
  @post_types ["standard", "date"]
  @date_categories ["restaurant", "cinema", "sport", "voyage", "cafe", "soiree", "culture", "plein_air", "randonnee", "musique", "gaming", "shopping", "brunch", "bien_etre", "art", "plage", "autre"]
  @date_budgets ["free", "low", "medium", "high"]
  @date_gender_prefs ["any", "male", "female", "non_binary"]
  @date_statuses ["open", "full", "completed", "cancelled"]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: false
    field :visibility, :string, default: "public"
    field :post_type, :string, default: "standard"

    # Date fields
    field :date_title, :string
    field :date_category, :string
    field :date_location, :string
    field :date_datetime, :utc_datetime
    field :date_budget, :string
    field :date_spots, :integer, default: 1
    field :date_gender_pref, :string, default: "any"
    field :date_age_min, :integer
    field :date_age_max, :integer
    field :date_status, :string, default: "open"

    belongs_to :user, User
    belongs_to :shared_post, __MODULE__
    has_many :shares, __MODULE__, foreign_key: :shared_post_id
    has_many :images, PostImage, on_delete: :delete_all
    has_many :comments, Comment, on_delete: :delete_all
    has_many :reactions, Reaction, on_delete: :delete_all
    has_many :date_applications, DateApplication, on_delete: :delete_all

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published, :user_id, :visibility, :shared_post_id, :post_type])
    |> validate_required([:user_id])
    |> validate_length(:title, max: 200)
    |> validate_inclusion(:visibility, @visibility_options)
    |> validate_inclusion(:post_type, @post_types)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:shared_post_id)
    |> validate_has_content_or_share()
  end

  def date_changeset(post, attrs) do
    post
    |> cast(attrs, [:body, :user_id, :visibility, :post_type,
      :date_title, :date_category, :date_location, :date_datetime,
      :date_budget, :date_spots, :date_gender_pref, :date_age_min, :date_age_max, :date_status])
    |> validate_required([:user_id, :date_title, :date_category, :date_datetime])
    |> validate_inclusion(:visibility, @visibility_options)
    |> validate_inclusion(:post_type, @post_types)
    |> validate_inclusion(:date_category, @date_categories)
    |> validate_inclusion(:date_budget, @date_budgets)
    |> validate_inclusion(:date_gender_pref, @date_gender_prefs)
    |> validate_inclusion(:date_status, @date_statuses)
    |> validate_number(:date_spots, greater_than: 0, less_than_or_equal_to: 20)
    |> validate_number(:date_age_min, greater_than_or_equal_to: 18, less_than_or_equal_to: 99)
    |> validate_number(:date_age_max, greater_than_or_equal_to: 18, less_than_or_equal_to: 99)
    |> validate_date_in_future()
    |> put_change(:post_type, "date")
    |> copy_date_title_to_title()
    |> foreign_key_constraint(:user_id)
  end

  defp validate_date_in_future(changeset) do
    case get_change(changeset, :date_datetime) do
      nil ->
        changeset

      datetime ->
        if DateTime.compare(datetime, DateTime.utc_now()) == :gt do
          changeset
        else
          add_error(changeset, :date_datetime, "doit être dans le futur")
        end
    end
  end

  # Copie date_title dans title pour satisfaire la contrainte NOT NULL
  defp copy_date_title_to_title(changeset) do
    case get_change(changeset, :date_title) do
      nil -> changeset
      date_title -> put_change(changeset, :title, date_title)
    end
  end

  # Valide qu'un post a soit un titre, soit un shared_post_id
  defp validate_has_content_or_share(changeset) do
    title = get_field(changeset, :title)
    body = get_field(changeset, :body)
    shared_post_id = get_field(changeset, :shared_post_id)

    has_content = (title && String.trim(title) != "") || (body && String.trim(body) != "")

    if !has_content && !shared_post_id do
      add_error(changeset, :title, "Un titre ou un contenu est requis")
    else
      changeset
    end
  end

  def visibility_options, do: @visibility_options

  def visibility_label("public"), do: "Public"
  def visibility_label("friends"), do: "Amis"
  def visibility_label("private"), do: "Moi uniquement"
  def visibility_label(_), do: "Public"

  def date_categories, do: @date_categories
  def date_budgets, do: @date_budgets
  def date_gender_prefs, do: @date_gender_prefs
  def date_statuses, do: @date_statuses

  def date_category_label("restaurant"), do: "Restaurant"
  def date_category_label("cinema"), do: "Cinéma"
  def date_category_label("sport"), do: "Sport"
  def date_category_label("voyage"), do: "Voyage"
  def date_category_label("cafe"), do: "Café"
  def date_category_label("soiree"), do: "Soirée"
  def date_category_label("culture"), do: "Culture"
  def date_category_label("plein_air"), do: "Plein air"
  def date_category_label("randonnee"), do: "Randonnée"
  def date_category_label("musique"), do: "Musique"
  def date_category_label("gaming"), do: "Gaming"
  def date_category_label("shopping"), do: "Shopping"
  def date_category_label("brunch"), do: "Brunch"
  def date_category_label("bien_etre"), do: "Bien-être"
  def date_category_label("art"), do: "Art"
  def date_category_label("plage"), do: "Plage"
  def date_category_label("autre"), do: "Autre"
  def date_category_label(_), do: "Autre"

  def date_category_emoji("restaurant"), do: "🍽️"
  def date_category_emoji("cinema"), do: "🎬"
  def date_category_emoji("sport"), do: "⚽"
  def date_category_emoji("voyage"), do: "✈️"
  def date_category_emoji("cafe"), do: "☕"
  def date_category_emoji("soiree"), do: "🎉"
  def date_category_emoji("culture"), do: "🎭"
  def date_category_emoji("plein_air"), do: "🌿"
  def date_category_emoji("randonnee"), do: "🥾"
  def date_category_emoji("musique"), do: "🎵"
  def date_category_emoji("gaming"), do: "🎮"
  def date_category_emoji("shopping"), do: "🛍️"
  def date_category_emoji("brunch"), do: "🥐"
  def date_category_emoji("bien_etre"), do: "🧘"
  def date_category_emoji("art"), do: "🎨"
  def date_category_emoji("plage"), do: "🏖️"
  def date_category_emoji("autre"), do: "💫"
  def date_category_emoji(_), do: "💫"

  def date_budget_label("free"), do: "Gratuit"
  def date_budget_label("low"), do: "€"
  def date_budget_label("medium"), do: "€€"
  def date_budget_label("high"), do: "€€€"
  def date_budget_label(_), do: "€"

  def date_gender_pref_label("any"), do: "Tout le monde"
  def date_gender_pref_label("male"), do: "Homme"
  def date_gender_pref_label("female"), do: "Femme"
  def date_gender_pref_label("non_binary"), do: "Non-binaire"
  def date_gender_pref_label(_), do: "Tout le monde"

  def date_status_label("open"), do: "Ouvert"
  def date_status_label("full"), do: "Complet"
  def date_status_label("completed"), do: "Passé"
  def date_status_label("cancelled"), do: "Annulé"
  def date_status_label(_), do: "Ouvert"
end
