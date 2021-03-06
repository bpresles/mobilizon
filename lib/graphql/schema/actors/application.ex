defmodule Mobilizon.GraphQL.Schema.Actors.ApplicationType do
  @moduledoc """
  Schema representation for Group.
  """

  use Absinthe.Schema.Notation

  @desc """
  Represents an application
  """
  object :application do
    interfaces([:actor])

    field(:id, :id, description: "Internal ID for this application")
    field(:url, :string, description: "The ActivityPub actor's URL")
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:local, :boolean, description: "If the actor is from this instance")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")

    field(:manually_approves_followers, :boolean,
      description: "Whether the actors manually approves followers"
    )

    field(:suspended, :boolean, description: "If the actor is suspended")

    field(:avatar, :picture, description: "The actor's avatar picture")
    field(:banner, :picture, description: "The actor's banner picture")

    # These one should have a privacy setting
    field(:following, list_of(:follower), description: "List of followings")
    field(:followers, list_of(:follower), description: "List of followers")
    field(:followersCount, :integer, description: "Number of followers for this actor")
    field(:followingCount, :integer, description: "Number of actors following this actor")
  end
end
