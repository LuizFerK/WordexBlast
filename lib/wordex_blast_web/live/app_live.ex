defmodule WordexBlastWeb.AppLive do
  use WordexBlastWeb, :live_view

  alias WordexBlast.Rooms

  def render(assigns) do
    ~H"""
    <img
      alt="Wordex Blast logo"
      src="images/logo.svg"
      width="300"
      class="mx-auto -mt-[55px] -mb-[35px]"
    />
    <div class="flex justify-center gap-8 pb-8 px-12">
      <div class="flex-1 max-w-screen-sm">
        <header class="border-dashed border-2 border-slate-50 rounded-3xl p-4 border-opacity-5">
          <div class="flex gap-2">
            <button
              class="text-center cursor-pointer bg-white bg-opacity-5 drop-shadow-lg rounded-xl py-2 flex-1 font-bold text-lg hover:bg-white hover:text-black"
              phx-click="create_room"
            >
              Create room
            </button>
            <span class="text-center bg-white drop-shadow-lg rounded-xl py-2 flex-1 font-bold text-lg text-black cursor-default">
              Play
            </span>
          </div>
          <div class="bg-slate-50 bg-opacity-5 rounded-2xl p-4 mt-2">
            <.flex_form for={@form} id="confirmation_form" phx-submit="enter_room">
              <.input
                maxlength="4"
                style="text-transform:uppercase; text-align:center"
                autocomplete="off"
                field={@form[:room_id]}
                placeholder="ROOM CODE"
                class="!mt-0 !border-opacity-5 font-bold"
                container_class="flex-1"
              />
              <.button class="bg-white">
                <.icon name="hero-arrow-right-solid" />
              </.button>
            </.flex_form>
          </div>
        </header>
        <section>
          <h1 class="mt-8 font-bold text-xl mb-2">Available rooms</h1>
          <div :if={@n_rooms == 0} class="flex flex-col items-center">
            <img alt="Space and planets" src="images/empty.svg" width="200" class="mx-auto" />
            <strong class="text-2xl">Oops...</strong>
            <p class="mt-2 mb-4 text-center">
              It looks like there are no rooms available to join
            </p>
            <.button>Create room</.button>
          </div>
          <ul id="rooms" phx-update="stream" class="grid grid-cols-3 gap-3">
            <.link
              :for={{room_id, room} <- @streams.rooms}
              id={room_id}
              navigate={~p"/play/#{room.id}"}
              class="bg-slate-50 bg-opacity-5 rounded-3xl p-3 py-6 text-center flex flex-col items-center font-bold"
            >
              <span>🇧🇷</span>
              <span class="mb-4 mt-3 font-bold text-3xl"><%= room.id %></span>
              <div class="flex items-center">
                <img alt="Player 1 avatar" src="images/avatar_1.png" class="w-7 h-8 z-20 -mt-1" />
                <img alt="Player 1 avatar" src="images/avatar_1.png" class="w-7 h-8 z-10 -ml-4 -mt-1" />
                <img alt="Player 1 avatar" src="images/avatar_1.png" class="w-7 h-8 -ml-4 -mt-1" />
                <span class="ml-2 font-light">+4</span>
              </div>
            </.link>
          </ul>
        </section>
      </div>
      <aside class="h-full sticky top-[88px]">
        <section class="border-dashed border-2 border-slate-50 rounded-3xl p-4 border-opacity-5 h-min">
          <div class="bg-slate-50 bg-opacity-5 rounded-2xl w-60 p-4 text-center text-xs">
            <div :if={!@current_user} class="flex flex-col items-center">
              <.icon name="hero-user-solid my-4" />
              <span class="text-sm">
                Connect to your account to enjoy 100% of the game experience!
              </span>
              <.link
                navigate={~p"/users/log_in"}
                class="my-4 p-3 rounded-xl w-full bg-slate-50 text-black font-bold text-sm"
              >
                Login
              </.link>
              <span>
                Don't have an account?
                <.link navigate={~p"/users/register"} class="font-bold">SignUp</.link>
              </span>
            </div>
            <div :if={@current_user} class="flex flex-col items-center text-sm py-3">
              <span>
                Welcome back!
              </span>
              <img alt="Player avatar" src="images/avatar_1.png" class="w-20 my-4" />
              <span class="font-bold text-lg">
                <%= @current_user.nickname %>
              </span>
              <div class="flex items-center gap-2 mt-4">
                <.icon name="hero-trophy-solid bg-yellow-400" />
                <span>200 pts</span>
              </div>
            </div>
          </div>
        </section>
        <section class="mt-6">
          <h2 class="font-bold">Leaderboard</h2>
          <ul>
            <li
              :for={{user, idx} <- @leaderboard}
              class="bg-slate-50 rounded-2xl bg-opacity-5 p-4 px-6 flex justify-between items-center mt-3"
            >
              <div class="flex items-center">
                <.icon name="hero-user-solid mr-3" />
                <span><%= user %></span>
              </div>
              <div class="flex items-center gap-2">
                <.icon :if={idx == 0} name="hero-trophy-solid bg-yellow-400" />
                <.icon :if={idx == 1} name="hero-trophy-solid bg-slate-300" />
                <.icon :if={idx == 2} name="hero-trophy-solid bg-amber-800" />
                <span>200</span>
              </div>
            </li>
          </ul>
        </section>
      </aside>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Rooms.subscribe()
    end

    rooms = Rooms.list_rooms()
    form = to_form(%{"room_id" => ""})

    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:n_rooms, length(rooms))
     |> assign(:leaderboard, Enum.with_index(["User 1", "User 2", "User 3", "User 4", "User 5"]))
     |> stream(:rooms, rooms), temporary_assigns: [form: nil]}
  end

  def handle_event("enter_room", %{"room_id" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("enter_room", %{"room_id" => room_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/play/#{String.upcase(room_id)}")}
  end

  def handle_event("create_room", _params, socket) do
    case Rooms.create_room() do
      {:ok, room} ->
        {:noreply, push_navigate(socket, to: ~p"/play/#{room.id}")}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def handle_info({:room_created, room}, socket) do
    socket = update(socket, :n_rooms, &(&1 + 1))
    {:noreply, stream_insert(socket, :rooms, room, at: 0)}
  end

  def handle_info({:room_deleted, room}, socket) do
    socket = update(socket, :n_rooms, &(&1 - 1))
    {:noreply, stream_delete(socket, :rooms, room)}
  end
end
