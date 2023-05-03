defmodule DigitsWeb.PageLive do
  @moduledoc """
  PageLive LiveView
  """
  use DigitsWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, %{prediction: nil})}
  end

  def render(assigns) do
    ~H"""
    <b>Draw a digit (0..9) within the canvas</b>

    <div id="wrapper" phx-update="ignore">
      <div id="canvas" phx-hook="Draw"></div>
    </div>

    <div class="mt-4">
      <button class="px-4 py-2 text-gray-500 border border-gray-200" phx-click="reset">Clear</button>
      <button class="px-4 py-2 text-white bg-blue-500" phx-click="predict">Predict</button>
    </div>

    <%= if @prediction do %>
    <div>
      <div>
        Prediction:
      </div>
      <div>
        <%= @prediction %>
      </div>
    </div>
    <% end %>
    """
  end

  def handle_event("reset", _params, socket) do
    {:noreply,
      socket
      |> assign(prediction: nil)
      |> push_event("reset", %{})
    }
  end

  def handle_event("predict", _params, socket) do
    {:noreply, push_event(socket, "predict", %{})}
  end

  def handle_event("image", "data:image/png;base64," <> raw, socket) do
    name = Base.url_encode64(:crypto.strong_rand_bytes(10), padding: false)
    path = Path.join(System.tmp_dir!(), "#{name}.webp")

    File.write!(path, Base.decode64!(raw))

    prediction = Digits.Model.predict(path)

    File.rm!(path)

    {:noreply, assign(socket, prediction: prediction)}
  end
end
