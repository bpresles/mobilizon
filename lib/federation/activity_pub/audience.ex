defmodule Mobilizon.Federation.ActivityPub.Audience do
  @moduledoc """
  Tools for calculating content audience
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Comment, Event, Participant}
  alias Mobilizon.Share
  alias Mobilizon.Storage.Repo

  require Logger

  @ap_public "https://www.w3.org/ns/activitystreams#Public"

  @doc """
  Determines the full audience based on mentions for a public audience

  Audience is:
    * `to` : the mentioned actors, the eventual actor we're replying to and the public
    * `cc` : the actor's followers
  """
  @spec get_to_and_cc(Actor.t(), list(), String.t()) :: {list(), list()}
  def get_to_and_cc(%Actor{} = actor, mentions, :public) do
    to = [@ap_public | mentions]
    cc = [actor.followers_url]

    {to, cc}
  end

  @doc """
  Determines the full audience based on mentions based on a unlisted audience

  Audience is:
    * `to` : the mentioned actors, actor's followers and the eventual actor we're replying to
    * `cc` : public
  """
  @spec get_to_and_cc(Actor.t(), list(), String.t()) :: {list(), list()}
  def get_to_and_cc(%Actor{} = actor, mentions, :unlisted) do
    to = [actor.followers_url | mentions]
    cc = [@ap_public]

    {to, cc}
  end

  @doc """
  Determines the full audience based on mentions based on a private audience

  Audience is:
    * `to` : the mentioned actors, actor's followers and the eventual actor we're replying to
    * `cc` : none
  """
  @spec get_to_and_cc(Actor.t(), list(), String.t()) :: {list(), list()}
  def get_to_and_cc(%Actor{} = actor, mentions, :private) do
    {to, cc} = get_to_and_cc(actor, mentions, :direct)
    {[actor.followers_url | to], cc}
  end

  @doc """
  Determines the full audience based on mentions based on a direct audience

  Audience is:
    * `to` : the mentioned actors and the eventual actor we're replying to
    * `cc` : none
  """
  @spec get_to_and_cc(Actor.t(), list(), String.t()) :: {list(), list()}
  def get_to_and_cc(_actor, mentions, :direct) do
    {mentions, []}
  end

  def get_to_and_cc(_actor, mentions, {:list, _}) do
    {mentions, []}
  end

  #  def get_addressed_actors(_, to) when is_list(to) do
  #    Actors.get(to)
  #  end

  def get_addressed_actors(mentioned_users, _), do: mentioned_users

  def calculate_to_and_cc_from_mentions(%Comment{} = comment) do
    with mentioned_actors <- Enum.map(comment.mentions, &process_mention/1),
         addressed_actors <- get_addressed_actors(mentioned_actors, nil),
         {to, cc} <- get_to_and_cc(comment.actor, addressed_actors, comment.visibility),
         {to, cc} <- {Enum.uniq(to ++ add_in_reply_to(comment.in_reply_to_comment)), cc},
         {to, cc} <- {Enum.uniq(to ++ add_event_author(comment.event)), cc},
         {to, cc} <-
           {to,
            Enum.uniq(
              cc ++
                add_comments_authors([comment.origin_comment]) ++
                add_shares_actors_followers(comment.url)
            )} do
      %{"to" => to, "cc" => cc}
    end
  end

  def calculate_to_and_cc_from_mentions(%Event{} = event) do
    with mentioned_actors <- Enum.map(event.mentions, &process_mention/1),
         addressed_actors <- get_addressed_actors(mentioned_actors, nil),
         {to, cc} <- get_to_and_cc(event.organizer_actor, addressed_actors, event.visibility),
         {to, cc} <-
           {to,
            Enum.uniq(
              cc ++ add_comments_authors(event.comments) ++ add_shares_actors_followers(event.url)
            )} do
      %{"to" => to, "cc" => cc}
    end
  end

  def calculate_to_and_cc_from_mentions(%Participant{} = participant) do
    participant = Repo.preload(participant, [:actor, :event])

    actor_participants_urls =
      participant.event.id
      |> Mobilizon.Events.list_actors_participants_for_event()
      |> Enum.map(& &1.url)

    %{"to" => [participant.actor.url], "cc" => actor_participants_urls}
  end

  def calculate_to_and_cc_from_mentions(%Actor{} = actor) do
    %{
      "to" => [@ap_public],
      "cc" => [actor.followers_url] ++ add_actors_that_had_our_content(actor.id)
    }
  end

  defp add_in_reply_to(%Comment{actor: %Actor{url: url}} = _comment), do: [url]
  defp add_in_reply_to(%Event{organizer_actor: %Actor{url: url}} = _event), do: [url]
  defp add_in_reply_to(_), do: []

  defp add_event_author(nil), do: []

  defp add_event_author(%Event{} = event) do
    [Repo.preload(event, [:organizer_actor]).organizer_actor.url]
  end

  defp add_comment_author(nil), do: nil

  defp add_comment_author(%Comment{} = comment) do
    case Repo.preload(comment, [:actor]) do
      %Comment{actor: %Actor{url: url}} ->
        url

      _err ->
        nil
    end
  end

  defp add_comments_authors(comments) do
    authors =
      comments
      |> Enum.map(&add_comment_author/1)
      |> Enum.filter(& &1)

    authors
  end

  @spec add_shares_actors_followers(String.t()) :: list(String.t())
  defp add_shares_actors_followers(uri) do
    uri
    |> Share.get_actors_by_share_uri()
    |> Enum.map(&Actors.list_followers_actors_for_actor/1)
    |> List.flatten()
    |> Enum.map(& &1.url)
    |> Enum.uniq()
  end

  defp add_actors_that_had_our_content(actor_id) do
    actor_id
    |> Share.get_actors_by_owner_actor_id()
    |> Enum.map(&Actors.list_followers_actors_for_actor/1)
    |> List.flatten()
    |> Enum.map(& &1.url)
    |> Enum.uniq()
  end

  defp process_mention({_, mentioned_actor}), do: mentioned_actor.url

  defp process_mention(%{actor_id: actor_id}) do
    with %Actor{url: url} <- Actors.get_actor(actor_id) do
      url
    end
  end
end
