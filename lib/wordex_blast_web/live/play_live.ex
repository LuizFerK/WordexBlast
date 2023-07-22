defmodule WordexBlastWeb.PlayLive do
  use WordexBlastWeb, :live_view

  alias WordexBlastWeb.Presence

  @topic "play:room"

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm flex flex-col">
      <li :for={{_user_id, meta} <- @presences}>
        <span>
          <%= meta.username %>
        </span>
      </li>
      <div class="flex-1">
        <.input
          name="word"
          value=""
          style="text-transform:uppercase; text-align:center"
          autocomplete="off"
        />
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WordexBlast.PubSub, @topic)

      {:ok, _} =
        Presence.track(self(), @topic, "test-#{Enum.random(0..1000)}", %{
          username: "test-#{Enum.random(0..1000)}"
        })
    end

    presences = Presence.list(@topic)

    socket =
      socket
      |> assign(:presences, simple_presence_map(presences))

    {:ok, socket}
  end

  def simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} ->
      {user_id, meta}
    end)
  end

  def handle_params(%{"game_code" => game_code}, _session, socket) do
    {:noreply, assign(socket, game_code: game_code)}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket =
      socket
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    {:noreply, socket}
  end

  defp remove_presences(socket, leaves) do
    user_ids = Enum.map(leaves, fn {user_id, _} -> user_id end)

    presences = Map.drop(socket.assigns.presences, user_ids)

    assign(socket, :presences, presences)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))
    assign(socket, :presences, presences)
  end
end
