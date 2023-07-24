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
      <.flex_form for={@form} id="confirmation_form" phx-submit="">
        <.input
          style="text-transform:uppercase; text-align:center"
          autocomplete="off"
          field={@form[:input]}
          placeholder="TYPE! QUICK!"
          class="!mt-0 font-bold border-none bg-white bg-opacity-5"
          container_class="flex-1 w-96"
        />
        <.button phx-disable-with="Confirming...">
          <.icon name="hero-arrow-right-solid" />
        </.button>
      </.flex_form>
    </div>
    <.modal id="setup-user" class="max-w-xl" show>
      <h1 class="font-bold text-xl mb-4">Welcome to Wordex Blast!</h1>
      <p>To start playing, let's setup your account.</p>
      <div class="w-full">
        <.simple_form for={@form} id="confirmation_form" phx-submit="">
          <.label>Avatar:</.label>
          <.input
            label="Nickname:"
            maxlength="4"
            autocomplete="off"
            field={@form[:input]}
            placeholder="My awesome nickname"
            class="font-bold text-center"
            container_class="mt-0"
          />
          <:actions>
            <.button class="w-full" phx-disable-with="Confirming...">
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

      if connected?(socket) do
        Phoenix.PubSub.subscribe(WordexBlast.PubSub, topic)
        Monitor.monitor(self(), room_id)

        IO.inspect("track")
        IO.inspect(self())

        {:ok, _} =
          Presence.track(self(), topic, "test-#{Enum.random(0..1000)}", %{
            username: "test-#{Enum.random(0..1000)}"
          })
      end

      form = to_form(%{"input" => ""})
      presences = Presence.list(topic)

      socket =
        socket
        |> assign(
          room_id: room_id,
          form: form,
          presences: simple_presence_map(presences)
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

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    IO.inspect(diff)

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
