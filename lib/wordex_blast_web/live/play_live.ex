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
            <span><%= @room.tick %></span>
          </div>
          <div :if={@room.status == "running"} class="bomb bomb_hint">
            <span class="text-black z-10 text-2xl mt-1" style="text-transform:uppercase;">
              <%= @room.hint %>
            </span>
            <img alt="Bomb" src="/images/white_logo.svg" width="114" />
            <div
              class="arrow"
              style={"--i:#{String.to_integer(elem(@room.selected_player, 0)) - 1};--x:#{Enum.count(@room.players)}"}
            />
          </div>
          <div :if={@room.status == "finished"} class="bomb">
            The winner is <%= elem(@room.selected_player, 1).username %>! <%= @room.tick %>
          </div>
          <div class="play-icon">
            <.user
              :for={{{_user_id, meta}, idx} <- Enum.with_index(@room.players)}
              user={meta}
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
          placeholder={get_placeholder(@current_player_selected, @room.selected_player)}
          class={
            class_join([
              {true, "!mt-0 font-bold border-none bg-white bg-opacity-5"},
              {!@current_player_selected, "cursor-not-allowed"}
            ])
          }
          container_class="flex-1 w-96"
          disabled={!@current_player_selected}
        />
        <.button disabled={!@current_player_selected} phx-disable-with="Confirming...">
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

  defp get_placeholder(_, {"", _}), do: "When the game starts, type here!"
  defp get_placeholder(true, _), do: "TYPE! QUICK!"
  defp get_placeholder(false, {_, %{username: username}}), do: "#{username} is playing..."

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
        <%= @user.username %>
        <div :if={@is_playing} class="lives">
          <div />
          <div class={[@user.lives <= 1 && "opacity-20"]} />
          <div class={[@user.lives <= 2 && "opacity-20"]} />
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"room_id" => room_id}, _session, socket) do
    room_id
    |> Rooms.get_room()
    |> mount_room(socket)
  end

  defp mount_room({:error, :not_found}, socket) do
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
        current_player_selected: false,
        play_form: play_form,
        user_form: user_form
      )

    {:ok, socket}
  end

  def handle_event("set_username", %{"username" => username}, socket) do
    {:noreply, assign(socket, :user_form, to_form(%{"username" => username}))}
  end

  def handle_event("set_user", %{"username" => username}, socket) do
    user = %{
      id: Ecto.UUID.generate(),
      idx: (socket.assigns.room.players |> Map.keys() |> length()) + 1,
      username: username,
      is_playing: !(socket.assigns.room.status == "running")
    }

    Rooms.track_player(self(), socket.assigns.room_id, user)

    {:noreply, assign(socket, :current_player, user)}
  end

  def handle_info({:room_updated, room}, socket) do
    selected_player_id =
      room.selected_player
      |> elem(1)
      |> Map.get(:id, nil)

    current_player_selected = socket.assigns.current_player.id == selected_player_id

    {:noreply, assign(socket, room: room, current_player_selected: current_player_selected)}
  end

  defp class_join(classes) do
    classes
    |> Enum.filter(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
    |> Enum.join(" ")
  end
end
