defmodule WordexBlastWeb.PlayLive do
  use WordexBlastWeb, :live_view

  alias WordexBlast.Rooms

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl flex flex-col items-center">
      <section class="h-[75vh] flex gap-8 items-center">
        <div class="play-container">
          <div :if={@room.status == "waiting"} class="bomb">Waiting for players...</div>
          <div :if={@room.status == "starting"} class="bomb">
            <h1>Game starts in</h1>
            <span>5</span>
          </div>
          <div :if={@room.status == "running"} class="bomb">
            <div
              class="arrow"
              style={"--i:#{String.to_integer(elem(@room.selected_player, 0)) - 1};--x:#{Enum.count(@room.players)}"}
            />
          </div>
          <div class="play-icon">
            <.user
              :for={{{_user_id, meta}, idx} <- Enum.with_index(@room.players)}
              username={meta.username}
              is_playing={meta.is_playing}
              is_selected={Map.get(elem(@room.selected_player, 1), :id) == meta.id}
              idx={idx}
              user_count={Enum.count(@room.players)}
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
      class={[
        "w-28 h-28 rounded-full bg-white text-black flex items-center justify-center font-bold play",
        !@is_playing && "opacity-30",
        @is_selected && "!bg-black text-white"
      ]}
      style={"--i:#{@idx};--x:#{@user_count}"}
    >
      <div>
        <%= @username %>
      </div>
    </div>
    """
  end

  def mount(%{"room_id" => room_id}, _session, socket) do
    room_id
    |> Rooms.get_room()
    |> mount_room(socket)
  end

  defp mount_room(nil, socket) do
    socket =
      socket
      |> put_flash(:error, "This room does not exists...")
      |> push_navigate(to: ~p(/app))

    {:ok, socket}
  end

  defp mount_room(room, socket) do
    current_player = Map.get(socket.assigns, :current_user)

    if connected?(socket) do
      Rooms.subscribe_to_room(room.id)
    end

    if current_player do
      Rooms.track_player(self(), room.id, %{
        id: current_player.id,
        idx: (room.players |> Map.keys() |> length()) + 1,
        username: current_player.email |> String.split("@") |> hd() |> String.capitalize(),
        is_playing: !(room.status == "running")
      })
    end

    play_form = to_form(%{"input" => ""})
    user_form = to_form(%{"username" => ""})

    socket =
      socket
      |> assign(
        room: room,
        room_id: room.id,
        current_player: current_player,
        play_form: play_form,
        user_form: user_form
      )

    {:ok, socket}
  end

  def handle_event("set_username", %{"username" => username}, socket) do
    {:noreply, assign(socket, :user_form, to_form(%{"username" => username}))}
  end

  def handle_event("set_user", %{"username" => username}, socket) do
    Rooms.track_player(self(), socket.assigns.room_id, %{
      id: Ecto.UUID.generate(),
      idx: (socket.assigns.room.players |> Map.keys() |> length()) + 1,
      username: username,
      is_playing: !(socket.assigns.room.status == "running")
    })

    {:noreply, assign(socket, :current_player, %{email: username})}
  end

  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign(socket, :room, room)}
  end
end
