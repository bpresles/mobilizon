defmodule Eventos.Factory do
  @moduledoc """
  Factory for fixtures with ExMachina
  """
  # with Ecto
  use ExMachina.Ecto, repo: Eventos.Repo

  def user_factory do
    %Eventos.Accounts.User{
      password_hash: "Jane Smith",
      email: sequence(:email, &"email-#{&1}@example.com"),
      role: 0,
      account: build(:account)
    }
  end

  def account_factory do
    {:ok, {_, pubkey}} = RsaEx.generate_keypair("4096")
    username = sequence("thomas")
    %Eventos.Accounts.Account{
      username: username,
      domain: nil,
      public_key: pubkey,
      url: EventosWeb.Endpoint.url() <> "/@#{username}"
    }
  end

  def category_factory do
    %Eventos.Events.Category{
      title: sequence("MyCategory"),
      description: "My category desc"
    }
  end

  def address_factory do
    %Eventos.Addresses.Address{
      description: sequence("MyAddress"),
      geom: %Geo.Point{coordinates: {30, -90}, srid: 4326},
      floor: "Myfloor",
      addressCountry: "My Country",
      addressLocality: "My Locality",
      addressRegion: "My Region",
      postalCode: "My Postal Code",
      streetAddress: "My Street Address"
    }
  end

  def event_factory do
    account = build(:account)
    slug = sequence("my-event")

    %Eventos.Events.Event{
      title: sequence("MyEvent"),
      slug: slug,
      description: "My desc",
      begins_on: nil,
      ends_on: nil,
      organizer_account: account,
      category: build(:category),
      address: build(:address),
      url: EventosWeb.Endpoint.url() <> "/@" <> account.username <> "/" <> slug
    }
  end

  def session_factory do
    %Eventos.Events.Session{
    title: sequence("MySession"),
    event: build(:event),
    track: build(:track)
    }
  end

  def track_factory do
    %Eventos.Events.Track{
      name: sequence("MyTrack"),
      event: build(:event)
    }
  end

  def group_factory do
    %Eventos.Groups.Group{
      title: sequence("My Group"),
      description: "My group",
      suspended: false,
      url: "https://",
      address: build(:address)
    }
  end
end
