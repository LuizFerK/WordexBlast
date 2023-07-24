defmodule WordexBlastWeb.PlayLive do
  use WordexBlastWeb, :live_view

  alias WordexBlast.Rooms
  alias WordexBlast.Rooms.Monitor
  alias WordexBlastWeb.Presence

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl flex flex-col items-center">
      <section class="h-[75vh] flex gap-8 items-center">
        <div class="play-container">
          <div :if={@game_state == "wait"} class="bomb">Waiting for players...</div>
          <div :if={@game_state == "running"} class="bomb">start</div>
          <div class="play-icon">
            <.user
              :for={{{_user_id, meta}, idx} <- Enum.with_index(@presences)}
              username={meta.username}
              idx={idx}
              user_count={Enum.count(@presences)}
            />
          </div>
        </div>
      </section>
      <.flex_form for={@play_form} id="play_form" phx-submit="">
        <.input
          style="text-transform:uppercase; text-align:center"
          autocomplete="off"
          field={@play_form[:input]}
          placeholder="TYPE! QUICK!"
          class="!mt-0 font-bold border-none bg-white bg-opacity-5"
          container_class="flex-1 w-96"
        />
        <.button phx-disable-with="Confirming...">
          <.icon name="hero-arrow-right-solid" />
        </.button>
      </.flex_form>
    </div>
    <.modal :if={!@current_player} id="setup-user" class="max-w-xl" show keep_open>
      <h1 class="font-bold text-xl mb-4">Welcome to Wordex Blast!</h1>
      <p>To start playing, let's setup your account.</p>
      <div class="w-full">
        <.simple_form for={@user_form} id="user_form" phx-change="set_username" phx-submit="set_user">
          <.label>Avatar:</.label>
          <.input
            label="Nickname:"
            maxlength="24"
            autocomplete="off"
            field={@user_form[:username]}
            placeholder="My awesome nickname"
            class="font-bold text-center"
            container_class="mt-0"
          />
          <:actions>
            <.button
              class="w-full"
              disabled={String.length(@user_form.params["username"]) < 4}
              phx-disable-with="Confirming..."
            >
              Start playing!
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  def user(assigns) do
    ~H"""
    <div
      class="w-28 h-28 rounded-full bg-white text-black flex items-center justify-center font-bold play"
      style={"--i:#{@idx};--x:#{@user_count}"}
    >
      <div>
        <%= @username %>
      </div>
    </div>
    """
  end

  def mount(%{"room_id" => room_id}, _session, socket) do
    if Rooms.get_room(room_id) != nil do
      topic = "play:#{room_id}"
      current_player = Map.get(socket.assigns, :current_user)

      if connected?(socket) do
        Phoenix.PubSub.subscribe(WordexBlast.PubSub, topic)
        Monitor.monitor(self(), room_id)

        if current_player do
          {:ok, _} =
            Presence.track(self(), topic, current_player.id, %{
              username: current_player.email |> String.split("@") |> hd() |> String.capitalize()
            })
        end
      end

      play_form = to_form(%{"input" => ""})
      user_form = to_form(%{"username" => ""})
      presences = Presence.list(topic)

      socket =
        socket
        |> assign(
          room_id: room_id,
          current_player: current_player,
          play_form: play_form,
          user_form: user_form,
          presences: simple_presence_map(presences),
          game_state: "wait"
        )

      {:ok, socket}
    else
      {:ok,
       socket |> put_flash(:error, "This room does not exists...") |> push_navigate(to: ~p(/app))}
    end
  end

  def simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} ->
      {user_id, meta}
    end)
  end

  def handle_event("set_username", %{"username" => username}, socket) do
    {:noreply, assign(socket, :user_form, to_form(%{"username" => username}))}
  end

  def handle_event("set_user", %{"username" => username}, socket) do
    Presence.track(self(), "play:#{socket.assigns.room_id}", Ecto.UUID.generate(), %{
      username: username
    })

    {:noreply, assign(socket, :current_player, %{email: username})}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket =
      socket
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    game_state =
      case Map.keys(socket.assigns.presences) |> length() do
        users_count when users_count < 2 -> "wait"
        _ -> "running"
      end

    {:noreply, assign(socket, :game_state, game_state)}
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
