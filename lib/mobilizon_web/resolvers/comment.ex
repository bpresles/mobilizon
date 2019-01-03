defmodule MobilizonWeb.Resolvers.Comment do
  @moduledoc """
  Handles the comment-related GraphQL calls
  """
  require Logger
  alias Mobilizon.Events.Comment
  alias Mobilizon.Activity
  alias Mobilizon.Actors.User
  alias MobilizonWeb.API.Comments

  def create_comment(_parent, %{text: comment, actor_username: username}, %{
        context: %{current_user: %User{} = _user}
      }) do
    with {:ok, %Activity{data: %{"object" => %{"type" => "Note"} = object}}} <-
           Comments.create_comment(username, comment) do
      {:ok,
       %Comment{
         text: object["content"],
         url: object["id"],
         uuid: object["uuid"]
       }}
    end
  end

  def create_comment(_parent, _args, %{}) do
    {:error, "You are not allowed to create a comment if not connected"}
  end
end
