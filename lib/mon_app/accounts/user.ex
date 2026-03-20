defmodule MonApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Blog.Post

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :password_hash, :string
    field :avatar, :string

    # Dating fields
    field :gender, :string
    field :bio, :string
    field :birthdate, :date
    field :looking_for, :string, default: "any"
    field :interests, {:array, :string}, default: []
    field :location, :string
    field :nationality, :string

    # Privacy settings
    field :show_dates_on_profile, :boolean, default: true
    field :show_posts_on_profile, :boolean, default: true

    # Account management
    field :scheduled_deletion_at, :naive_datetime
    field :role, :string, default: "user"

    # Champ virtuel (pas en DB)
    field :password, :string, virtual: true

    # Relation : un user a plusieurs posts
    has_many :posts, Post

    timestamps()
  end

  @genders ["male", "female", "non_binary", "other"]
  @looking_for_options ["any", "male", "female", "non_binary", "friends"]
  @roles ["user", "moderator", "admin"]

  @doc "Changeset pour modifier un user (sans password)"
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email], message: "ce champ est requis")
    |> validate_format(:email, ~r/@/, message: "doit être un email valide")
    |> validate_length(:name, min: 3, max: 20, message: "doit contenir entre 3 et 20 caractères")
    |> validate_format(:name, ~r/^[a-zA-Z0-9_]+$/, message: "uniquement lettres, chiffres et _")
    |> validate_number(:age, greater_than: 0, message: "doit être supérieur à 0")
    |> unique_constraint(:name, message: "ce pseudo est déjà pris")
    |> unique_constraint(:email, message: "cet email est déjà utilisé")
  end

  @doc "Changeset pour le profil dating"
  def dating_changeset(user, attrs) do
    user
    |> cast(attrs, [:bio, :gender, :birthdate, :looking_for, :interests, :location])
    |> validate_inclusion(:gender, @genders)
    |> validate_inclusion(:looking_for, @looking_for_options)
    |> validate_length(:bio, max: 500, message: "500 caractères maximum")
    |> validate_length(:location, max: 100, message: "100 caractères maximum")
  end

  def genders, do: @genders
  def looking_for_options, do: @looking_for_options
  def roles, do: @roles

  def admin?(%__MODULE__{role: role}), do: role in ["admin", "moderator"]
  def super_admin?(%__MODULE__{role: "admin"}), do: true
  def super_admin?(_), do: false

  def gender_label("male"), do: "Homme"
  def gender_label("female"), do: "Femme"
  def gender_label("non_binary"), do: "Non-binaire"
  def gender_label("other"), do: "Autre"
  def gender_label(_), do: nil

  @nationalities [
    {"AF", "🇦🇫", "Afghane"},
    {"ZA", "🇿🇦", "Sud-Africaine"},
    {"AL", "🇦🇱", "Albanaise"},
    {"DZ", "🇩🇿", "Algérienne"},
    {"DE", "🇩🇪", "Allemande"},
    {"AD", "🇦🇩", "Andorrane"},
    {"AO", "🇦🇴", "Angolaise"},
    {"AG", "🇦🇬", "Antiguaise"},
    {"SA", "🇸🇦", "Saoudienne"},
    {"AR", "🇦🇷", "Argentine"},
    {"AM", "🇦🇲", "Arménienne"},
    {"AU", "🇦🇺", "Australienne"},
    {"AT", "🇦🇹", "Autrichienne"},
    {"AZ", "🇦🇿", "Azerbaïdjanaise"},
    {"BS", "🇧🇸", "Bahamienne"},
    {"BH", "🇧🇭", "Bahreïnienne"},
    {"BD", "🇧🇩", "Bangladaise"},
    {"BB", "🇧🇧", "Barbadienne"},
    {"BE", "🇧🇪", "Belge"},
    {"BZ", "🇧🇿", "Bélizienne"},
    {"BJ", "🇧🇯", "Béninoise"},
    {"BT", "🇧🇹", "Bhoutanaise"},
    {"BY", "🇧🇾", "Biélorusse"},
    {"MM", "🇲🇲", "Birmane"},
    {"BO", "🇧🇴", "Bolivienne"},
    {"BA", "🇧🇦", "Bosnienne"},
    {"BW", "🇧🇼", "Botswanaise"},
    {"BR", "🇧🇷", "Brésilienne"},
    {"BN", "🇧🇳", "Brunéienne"},
    {"BG", "🇧🇬", "Bulgare"},
    {"BF", "🇧🇫", "Burkinabè"},
    {"BI", "🇧🇮", "Burundaise"},
    {"KH", "🇰🇭", "Cambodgienne"},
    {"CM", "🇨🇲", "Camerounaise"},
    {"CA", "🇨🇦", "Canadienne"},
    {"CV", "🇨🇻", "Cap-Verdienne"},
    {"CF", "🇨🇫", "Centrafricaine"},
    {"CL", "🇨🇱", "Chilienne"},
    {"CN", "🇨🇳", "Chinoise"},
    {"CY", "🇨🇾", "Chypriote"},
    {"CO", "🇨🇴", "Colombienne"},
    {"KM", "🇰🇲", "Comorienne"},
    {"CG", "🇨🇬", "Congolaise (Brazza)"},
    {"CD", "🇨🇩", "Congolaise (RDC)"},
    {"KR", "🇰🇷", "Coréenne du Sud"},
    {"KP", "🇰🇵", "Coréenne du Nord"},
    {"CR", "🇨🇷", "Costaricaine"},
    {"CI", "🇨🇮", "Ivoirienne"},
    {"HR", "🇭🇷", "Croate"},
    {"CU", "🇨🇺", "Cubaine"},
    {"DK", "🇩🇰", "Danoise"},
    {"DJ", "🇩🇯", "Djiboutienne"},
    {"DM", "🇩🇲", "Dominiquaise"},
    {"DO", "🇩🇴", "Dominicaine"},
    {"EG", "🇪🇬", "Égyptienne"},
    {"AE", "🇦🇪", "Émiratie"},
    {"EC", "🇪🇨", "Équatorienne"},
    {"ER", "🇪🇷", "Érythréenne"},
    {"ES", "🇪🇸", "Espagnole"},
    {"EE", "🇪🇪", "Estonienne"},
    {"SZ", "🇸🇿", "Eswatinienne"},
    {"ET", "🇪🇹", "Éthiopienne"},
    {"FJ", "🇫🇯", "Fidjienne"},
    {"FI", "🇫🇮", "Finlandaise"},
    {"FR", "🇫🇷", "Française"},
    {"GA", "🇬🇦", "Gabonaise"},
    {"GM", "🇬🇲", "Gambienne"},
    {"GE", "🇬🇪", "Géorgienne"},
    {"GH", "🇬🇭", "Ghanéenne"},
    {"GR", "🇬🇷", "Grecque"},
    {"GD", "🇬🇩", "Grenadienne"},
    {"GT", "🇬🇹", "Guatémaltèque"},
    {"GN", "🇬🇳", "Guinéenne"},
    {"GW", "🇬🇼", "Bissau-Guinéenne"},
    {"GQ", "🇬🇶", "Équato-Guinéenne"},
    {"GY", "🇬🇾", "Guyanienne"},
    {"HT", "🇭🇹", "Haïtienne"},
    {"HN", "🇭🇳", "Hondurienne"},
    {"HU", "🇭🇺", "Hongroise"},
    {"IN", "🇮🇳", "Indienne"},
    {"ID", "🇮🇩", "Indonésienne"},
    {"IQ", "🇮🇶", "Irakienne"},
    {"IR", "🇮🇷", "Iranienne"},
    {"IE", "🇮🇪", "Irlandaise"},
    {"IS", "🇮🇸", "Islandaise"},
    {"IL", "🇮🇱", "Israélienne"},
    {"IT", "🇮🇹", "Italienne"},
    {"JM", "🇯🇲", "Jamaïcaine"},
    {"JP", "🇯🇵", "Japonaise"},
    {"JO", "🇯🇴", "Jordanienne"},
    {"KZ", "🇰🇿", "Kazakhe"},
    {"KE", "🇰🇪", "Kényane"},
    {"KG", "🇰🇬", "Kirghize"},
    {"KI", "🇰🇮", "Kiribatienne"},
    {"KW", "🇰🇼", "Koweïtienne"},
    {"LA", "🇱🇦", "Laotienne"},
    {"LS", "🇱🇸", "Lésothane"},
    {"LV", "🇱🇻", "Lettone"},
    {"LB", "🇱🇧", "Libanaise"},
    {"LR", "🇱🇷", "Libérienne"},
    {"LY", "🇱🇾", "Libyenne"},
    {"LI", "🇱🇮", "Liechtensteinoise"},
    {"LT", "🇱🇹", "Lituanienne"},
    {"LU", "🇱🇺", "Luxembourgeoise"},
    {"MK", "🇲🇰", "Macédonienne"},
    {"MG", "🇲🇬", "Malagasy"},
    {"MY", "🇲🇾", "Malaisienne"},
    {"MW", "🇲🇼", "Malawienne"},
    {"MV", "🇲🇻", "Maldivienne"},
    {"ML", "🇲🇱", "Malienne"},
    {"MT", "🇲🇹", "Maltaise"},
    {"MA", "🇲🇦", "Marocaine"},
    {"MU", "🇲🇺", "Mauricienne"},
    {"MR", "🇲🇷", "Mauritanienne"},
    {"MX", "🇲🇽", "Mexicaine"},
    {"MD", "🇲🇩", "Moldave"},
    {"MC", "🇲🇨", "Monégasque"},
    {"MN", "🇲🇳", "Mongole"},
    {"ME", "🇲🇪", "Monténégrine"},
    {"MZ", "🇲🇿", "Mozambicaine"},
    {"NA", "🇳🇦", "Namibienne"},
    {"NR", "🇳🇷", "Nauruane"},
    {"NP", "🇳🇵", "Népalaise"},
    {"NI", "🇳🇮", "Nicaraguayenne"},
    {"NE", "🇳🇪", "Nigérienne"},
    {"NG", "🇳🇬", "Nigériane"},
    {"NO", "🇳🇴", "Norvégienne"},
    {"NZ", "🇳🇿", "Néo-Zélandaise"},
    {"OM", "🇴🇲", "Omanaise"},
    {"UG", "🇺🇬", "Ougandaise"},
    {"UZ", "🇺🇿", "Ouzbèke"},
    {"PK", "🇵🇰", "Pakistanaise"},
    {"PW", "🇵🇼", "Palaosienne"},
    {"PS", "🇵🇸", "Palestinienne"},
    {"PA", "🇵🇦", "Panaméenne"},
    {"PG", "🇵🇬", "Papouane-Néo-Guinéenne"},
    {"PY", "🇵🇾", "Paraguayenne"},
    {"NL", "🇳🇱", "Néerlandaise"},
    {"PE", "🇵🇪", "Péruvienne"},
    {"PH", "🇵🇭", "Philippine"},
    {"PL", "🇵🇱", "Polonaise"},
    {"PT", "🇵🇹", "Portugaise"},
    {"QA", "🇶🇦", "Qatarienne"},
    {"RO", "🇷🇴", "Roumaine"},
    {"GB", "🇬🇧", "Britannique"},
    {"RU", "🇷🇺", "Russe"},
    {"RW", "🇷🇼", "Rwandaise"},
    {"KN", "🇰🇳", "Saint-Kittsienne"},
    {"LC", "🇱🇨", "Saint-Lucienne"},
    {"VC", "🇻🇨", "Vincentaise"},
    {"SB", "🇸🇧", "Salomonaise"},
    {"WS", "🇼🇸", "Samoane"},
    {"ST", "🇸🇹", "Santoméenne"},
    {"SN", "🇸🇳", "Sénégalaise"},
    {"RS", "🇷🇸", "Serbe"},
    {"SC", "🇸🇨", "Seychelloise"},
    {"SL", "🇸🇱", "Sierra-Léonaise"},
    {"SG", "🇸🇬", "Singapourienne"},
    {"SK", "🇸🇰", "Slovaque"},
    {"SI", "🇸🇮", "Slovène"},
    {"SO", "🇸🇴", "Somalienne"},
    {"SD", "🇸🇩", "Soudanaise"},
    {"SS", "🇸🇸", "Sud-Soudanaise"},
    {"LK", "🇱🇰", "Sri-Lankaise"},
    {"SE", "🇸🇪", "Suédoise"},
    {"CH", "🇨🇭", "Suisse"},
    {"SR", "🇸🇷", "Surinamaise"},
    {"SY", "🇸🇾", "Syrienne"},
    {"TJ", "🇹🇯", "Tadjike"},
    {"TZ", "🇹🇿", "Tanzanienne"},
    {"TD", "🇹🇩", "Tchadienne"},
    {"CZ", "🇨🇿", "Tchèque"},
    {"TH", "🇹🇭", "Thaïlandaise"},
    {"TL", "🇹🇱", "Timoraise"},
    {"TG", "🇹🇬", "Togolaise"},
    {"TO", "🇹🇴", "Tongienne"},
    {"TT", "🇹🇹", "Trinidadienne"},
    {"TN", "🇹🇳", "Tunisienne"},
    {"TM", "🇹🇲", "Turkmène"},
    {"TR", "🇹🇷", "Turque"},
    {"TV", "🇹🇻", "Tuvaluane"},
    {"UA", "🇺🇦", "Ukrainienne"},
    {"UY", "🇺🇾", "Uruguayenne"},
    {"US", "🇺🇸", "Américaine"},
    {"VU", "🇻🇺", "Vanuatuane"},
    {"VE", "🇻🇪", "Vénézuélienne"},
    {"VN", "🇻🇳", "Vietnamienne"},
    {"YE", "🇾🇪", "Yéménite"},
    {"ZM", "🇿🇲", "Zambienne"},
    {"ZW", "🇿🇼", "Zimbabwéenne"}
  ]

  def nationalities, do: @nationalities

  def nationality_flag(code) do
    case Enum.find(@nationalities, fn {c, _, _} -> c == code end) do
      {_, flag, _} -> flag
      _ -> "🏳️"
    end
  end

  def nationality_label(code) do
    case Enum.find(@nationalities, fn {c, _, _} -> c == code end) do
      {_, _, label} -> label
      _ -> nil
    end
  end

  def looking_for_label("any"), do: "Tout le monde"
  def looking_for_label("male"), do: "Hommes"
  def looking_for_label("female"), do: "Femmes"
  def looking_for_label("non_binary"), do: "Non-binaires"
  def looking_for_label("friends"), do: "Amis uniquement"
  def looking_for_label(_), do: "Tout le monde"

  @doc "Changeset pour inscription (avec password)"
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password], message: "ce champ est requis")
    |> validate_length(:name, min: 3, max: 20, message: "doit contenir entre 3 et 20 caractères")
    |> validate_format(:name, ~r/^[a-zA-Z0-9_]+$/, message: "uniquement lettres, chiffres et _")
    |> validate_format(:email, ~r/@/, message: "doit être un email valide")
    |> validate_length(:password, min: 6, max: 100, message: "doit contenir au moins 6 caractères")
    |> unique_constraint(:name, message: "ce pseudo est déjà pris")
    |> unique_constraint(:email, message: "cet email est déjà utilisé")
    |> hash_password()
  end

  @doc "Changeset pour modifier le profil complet"
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:bio, :gender, :birthdate, :looking_for, :location, :nationality, :show_dates_on_profile, :show_posts_on_profile])
    |> validate_length(:bio, max: 500, message: "500 caractères maximum")
    |> validate_length(:location, max: 100, message: "100 caractères maximum")
    |> validate_inclusion(:gender, @genders ++ [nil, ""], message: "choix invalide")
    |> validate_inclusion(:looking_for, @looking_for_options, message: "choix invalide")
  end

  @doc "Changeset pour mettre à jour l'avatar"
  def avatar_changeset(user, attrs) do
    user
    |> cast(attrs, [:avatar])
  end

  @doc "Changeset pour planifier/annuler la suppression"
  def deletion_changeset(user, attrs) do
    user
    |> cast(attrs, [:scheduled_deletion_at])
  end

  @doc "Changeset pour modifier le rôle (admin uniquement)"
  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_inclusion(:role, @roles, message: "rôle invalide")
  end

  # Hash le password avant insertion
  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end
end
