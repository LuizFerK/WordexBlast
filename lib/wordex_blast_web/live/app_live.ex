defmodule WordexBlastWeb.AppLive do
  use WordexBlastWeb, :live_view

  alias WordexBlast.Rooms

  def render(assigns) do
    ~H"""
    <div class="flex justify-center gap-8 pb-8">
      <div class="flex-1 max-w-screen-sm">
        <header class="border-dashed border-2 border-slate-50 rounded-lg p-4 border-opacity-5">
          <div class="flex gap-2">
            <button
              class="text-center cursor-pointer bg-white bg-opacity-5 drop-shadow-lg rounded-lg py-2 flex-1 font-bold text-lg hover:bg-white hover:text-black"
              phx-click="create_room"
            >
              Create room
            </button>
            <span class="text-center bg-white drop-shadow-lg rounded-lg py-2 flex-1 font-bold text-lg text-black cursor-default">
              Play
            </span>
          </div>
          <div class="bg-slate-50 bg-opacity-5 rounded-lg p-4 mt-2">
            <.flex_form for={@form} id="confirmation_form" phx-submit="enter_room">
              <.input
                maxlength="4"
                style="text-transform:uppercase; text-align:center"
                autocomplete="off"
                field={@form[:room_code]}
                placeholder="ROOM CODE"
                class="!mt-0 !border-opacity-5 font-bold"
                container_class="flex-1"
              />
              <.button phx-disable-with="Confirming...">
                <.icon name="hero-arrow-right-solid" />
              </.button>
            </.flex_form>
          </div>
        </header>
        <section>
          <h1 class="mt-4 font-bold text-2xl mb-2">Available servers</h1>
          <ul class="grid grid-cols-3 gap-3">
            <li
              :for={room <- @rooms}
              class="bg-slate-50 bg-opacity-5 rounded-lg p-4 py-6 text-center flex flex-col items-center font-bold"
            >
              <div class="w-20 h-20 bg-white rounded-full" />
              <span class="my-4"><%= room.code %></span>
              <div class="flex items-center">
                <div class="w-8 h-8 bg-white rounded-full z-20" />
                <div class="w-8 h-8 bg-black rounded-full z-10 -ml-4" />
                <div class="w-8 h-8 bg-white rounded-full -ml-4" />
                <span class="ml-2">+4</span>
              </div>
            </li>
          </ul>
        </section>
      </div>
      <aside class="h-full sticky top-[88px]">
        <section class="border-dashed border-2 border-slate-50 rounded-lg p-4 border-opacity-5 h-min">
          <div class="bg-slate-50 bg-opacity-5 rounded-lg w-60 p-4 text-center flex flex-col items-center text-xs">
            <.icon name="hero-user-solid my-4" />
            <span class="text-sm">Connect to your account to enjoy 100% of the game experience!</span>
            <.button class="mt-4 mb-3 w-full">Login</.button>
            <span>Don't have an account? <a href="" class="font-bold">SignUp</a></span>
          </div>
        </section>
        <section class="mt-6">
          <h2 class="font-bold">Leaderboard</h2>
          <ul>
            <li
              :for={{user, idx} <- @leaderboard}
              class="bg-slate-50 rounded-lg bg-opacity-5 p-4 px-6 flex justify-between items-center mt-3"
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
    form = to_form(%{"room_code" => ""})

    {:ok,
     assign(socket,
       form: form,
       leaderboard: Enum.with_index(["User 1", "User 2", "User 3", "User 4", "User 5"]),
       rooms: Rooms.list_rooms()
     ), temporary_assigns: [form: nil]}
  end

  def handle_event("enter_room", %{"room_code" => room_code}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/play/#{String.upcase(room_code)}")}
  end

  def handle_event("create_room", _params, socket) do
    case Rooms.create_room() do
      {:ok, room} ->
        {:noreply, push_navigate(socket, to: ~p"/play/#{room.code}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error while creating a new room. Try again!")}
    end
  end
end
