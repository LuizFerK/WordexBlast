defmodule WordexBlastWeb.PlayLive do
  use WordexBlastWeb, :live_view

  alias WordexBlast.Rooms
  alias WordexBlastWeb.Presence

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
          <div :if={@room.status == "running"} class="bomb">start</div>
          <div class="play-icon">
            <.user
              :for={{{_user_id, meta}, idx} <- Enum.with_index(@room.players)}
              username={meta.username}
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
    room = Rooms.get_room(room_id)

    if room != nil do
      current_player = Map.get(socket.assigns, :current_user)

      if connected?(socket) do
        Rooms.subscribe_to_room(room_id)

        if current_player do
          {:ok, _} =
            Presence.track(self(), "presence:#{room_id}", current_player.id, %{
              username: current_player.email |> String.split("@") |> hd() |> String.capitalize()
            })
        end
      end

      play_form = to_form(%{"input" => ""})
      user_form = to_form(%{"username" => ""})

      socket =
        socket
        |> assign(
          room: room,
          room_id: room_id,
          current_player: current_player,
          play_form: play_form,
          user_form: user_form
        )

      {:ok, socket}
    else
      {:ok,
       socket |> put_flash(:error, "This room does not exists...") |> push_navigate(to: ~p(/app))}
    end
  end

  def handle_event("set_username", %{"username" => username}, socket) do
    {:noreply, assign(socket, :user_form, to_form(%{"username" => username}))}
  end

  def handle_event("set_user", %{"username" => username}, socket) do
    Presence.track(self(), "presence:#{socket.assigns.room_id}", Ecto.UUID.generate(), %{
      username: username
    })

    {:noreply, assign(socket, :current_player, %{email: username})}
  end

  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign(socket, :room, room)}
  end

  # # Starting game
  # def handle_info({:update_state, "starting", "wait", _tick}, socket) do
  #   send(self(), {:update_state, "starting", "starting", socket.assigns.start_countdown - 1})
  #   {:noreply, assign(socket, :game_state, "starting")}
  # end

  # # Starting countdown ends
  # def handle_info({:update_state, "starting", "starting", 0}, socket) do
  #   :timer.sleep(1000)
  #   send(self(), {:update_state, "running", "starting", nil})
  #   {:noreply, assign(socket, :start_countdown, "GO!")}
  # end

  # # Starting countdown tick
  # def handle_info({:update_state, "starting", "starting", tick}, socket) do
  #   :timer.sleep(1000)
  #   send(self(), {:update_state, "starting", "starting", tick - 1})
  #   {:noreply, assign(socket, :start_countdown, tick)}
  # end

  # # Start game
  # def handle_info({:update_state, "running", "starting", _tick}, socket) do
  #   :timer.sleep(1000)
  #   {:noreply, assign(socket, :game_state, "running")}
  # end
end
