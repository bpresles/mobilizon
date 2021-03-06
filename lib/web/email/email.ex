defmodule Mobilizon.Web.Email do
  @moduledoc """
  The Email context.
  """

  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  alias Mobilizon.Config

  alias Mobilizon.Web.EmailView

  @spec base_email(keyword()) :: Bamboo.Email.t()
  def base_email(args) do
    instance = Config.instance_config()

    args
    |> new_email()
    |> from({Config.instance_name(), Config.instance_email_from()})
    |> put_header("Reply-To", Config.instance_email_reply_to())
    |> assign(:instance, instance)
    |> put_html_layout({EmailView, "email.html"})
    |> put_text_layout({EmailView, "email.text"})
  end
end
