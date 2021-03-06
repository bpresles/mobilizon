defmodule Mobilizon.GraphQL.Resolvers.Config do
  @moduledoc """
  Handles the config-related GraphQL calls.
  """

  alias Geolix.Adapter.MMDB2.Record.{Country, Location}

  alias Mobilizon.Config

  @doc """
  Gets config.
  """
  def get_config(_parent, _params, %{context: %{ip: ip}}) do
    geolix = Geolix.lookup(ip)

    country_code =
      case Map.get(geolix, :city) do
        %{country: %Country{iso_code: country_code}} -> String.downcase(country_code)
        _ -> nil
      end

    location =
      case Map.get(geolix, :city) do
        %{location: %Location{} = location} -> Map.from_struct(location)
        _ -> nil
      end

    data = Map.merge(config_cache(), %{location: location, country_code: country_code})

    {:ok, data}
  end

  def terms(_parent, %{locale: locale}, _resolution) do
    type = Config.instance_terms_type()

    {url, body_html} =
      case type do
        "URL" -> {Config.instance_terms_url(), nil}
        "DEFAULT" -> {nil, Config.generate_terms(locale)}
        _ -> {nil, Config.instance_terms(locale)}
      end

    {:ok, %{body_html: body_html, type: type, url: url}}
  end

  defp config_cache do
    case Cachex.fetch(:config, "full_config", fn _key ->
           case build_config_cache() do
             value when not is_nil(value) -> {:commit, value}
             err -> {:ignore, err}
           end
         end) do
      {status, value} when status in [:ok, :commit] -> value
      _err -> nil
    end
  end

  defp build_config_cache do
    %{
      name: Config.instance_name(),
      registrations_open: Config.instance_registrations_open?(),
      registrations_whitelist: Config.instance_registrations_whitelist?(),
      demo_mode: Config.instance_demo_mode?(),
      description: Config.instance_description(),
      anonymous: %{
        participation: %{
          allowed: Config.anonymous_participation?(),
          validation: %{
            email: %{
              enabled: Config.anonymous_participation_email_required?(),
              confirmation_required:
                Config.anonymous_event_creation_email_confirmation_required?()
            },
            captcha: %{
              enabled: Config.anonymous_event_creation_email_captcha_required?()
            }
          }
        },
        event_creation: %{
          allowed: Config.anonymous_event_creation?(),
          validation: %{
            email: %{
              enabled: Config.anonymous_event_creation_email_required?(),
              confirmation_required:
                Config.anonymous_event_creation_email_confirmation_required?()
            },
            captcha: %{
              enabled: Config.anonymous_event_creation_email_captcha_required?()
            }
          }
        },
        actor_id: Config.anonymous_actor_id()
      },
      geocoding: %{
        provider: Config.instance_geocoding_provider(),
        autocomplete: Config.instance_geocoding_autocomplete()
      },
      maps: %{
        tiles: %{
          endpoint: Config.instance_maps_tiles_endpoint(),
          attribution: Config.instance_maps_tiles_attribution()
        }
      }
    }
  end
end
