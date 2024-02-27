defmodule DigitsWeb.PageLive do
  @moduledoc """
  PageLive LiveView
  """

  use DigitsWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    Process.send_after(self(), "tick", 1000)
    {:ok, assign(socket, %{prediction: nil})}
  end

  def render(assigns) do
    ~H"""
    <div id="wrapper" phx-update="ignore">
      <div id="canvas" phx-hook="Draw"></div>
    </div>

    <div>
      <button
        class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        phx-click="reset"
      >
        Reset
      </button>
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

  def handle_info("tick", socket) do
    Process.send_after(self(), "tick", 1000)
    Logger.info("tick")
    {:noreply, push_event(socket, "predict", %{})}
  end

  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(prediction: nil)
     |> push_event("reset", %{})}
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
