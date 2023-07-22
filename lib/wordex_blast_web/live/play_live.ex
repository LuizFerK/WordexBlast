defmodule WordexBlastWeb.PlayLive do
  use WordexBlastWeb, :live_view

  def render(assigns) do
    ~H"""
    <p><%= @game_id %></p>
    <%!-- <div class="bg-cyan-700 mx-auto max-w-sm">
      <.simple_form for={@form} id="confirmation_form" phx-submit="enter_game">
        <.input maxlength="4" style="text-transform:uppercase; text-align:center" autocomplete="off" field={@form[:game_code]} />
        <:actions>
          <.button phx-disable-with="Confirming..." class="w-full">Enter game</.button>
        </:actions>
      </.simple_form>
    </div> --%>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"game_id" => game_id}, _session, socket) do
    {:noreply, assign(socket, game_id: game_id)}
  end

  # def handle_event("enter_game", %{"game_code" => game_code}, socket) do
  #   {:noreply, redirect(socket, to: ~p"/play/#{String.upcase(game_code)}")}
  #   # {:noreply, socket}
  # end
end
