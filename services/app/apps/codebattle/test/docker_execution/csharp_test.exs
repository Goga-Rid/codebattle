defmodule Codebattle.DockerExecution.CsharpTest do
  use Codebattle.IntegrationCase

  alias Codebattle.CodeCheck.Result
  alias Codebattle.Game
  alias CodebattleWeb.GameChannel
  alias CodebattleWeb.UserSocket
  alias Phoenix.Socket.Broadcast

  setup do
    user1 = insert(:user)
    user2 = insert(:user)
    task = insert(:task)
    socket1 = socket(UserSocket, "user_id", %{user_id: user1.id, current_user: user1})
    socket2 = socket(UserSocket, "user_id", %{user_id: user2.id, current_user: user2})
    game_params = %{state: "playing", players: [user1, user2], task: task}

    {:ok, %{game_params: game_params, socket1: socket1, socket2: socket2}}
  end

  @tag :docker_executor
  test "error code, game playing", %{
    game_params: game_params,
    socket1: socket1,
    socket2: socket2
  } do
    {:ok, game} = Game.Context.create_game(game_params)
    game_topic = "game:" <> to_string(game.id)

    {:ok, _response, socket1} = subscribe_and_join(socket1, GameChannel, game_topic)
    {:ok, _response, _socket2} = subscribe_and_join(socket2, GameChannel, game_topic)
    Mix.Shell.Process.flush()

    Phoenix.ChannelTest.push(socket1, "check_result", %{editor_text: "sdf\n", lang_slug: "csharp"})

    assert_code_check()

    assert_receive %Broadcast{
      payload: %{check_result: check_result}
    }

    assert %Result{status: "error", success_count: 0} = check_result

    game = Game.Context.get_game!(game.id)
    assert game.state == "playing"
  end

  @tag :docker_executor
  test "failure code, game playing", %{
    game_params: game_params,
    socket1: socket1,
    socket2: socket2
  } do
    {:ok, game} = Game.Context.create_game(game_params)
    game_topic = "game:" <> to_string(game.id)

    {:ok, _response, socket1} = subscribe_and_join(socket1, GameChannel, game_topic)
    {:ok, _response, _socket2} = subscribe_and_join(socket2, GameChannel, game_topic)
    Mix.Shell.Process.flush()

    Phoenix.ChannelTest.push(socket1, "check_result", %{
      editor_text: "using System; \n
        namespace app{ public class Solution { public int solution(int a, int b) { return a - b; } } }",
      lang_slug: "csharp"
    })

    assert_code_check()

    assert_receive %Broadcast{
      payload: %{check_result: check_result}
    }

    assert %Result{status: "failure", success_count: 0} = check_result

    game = Game.Context.get_game!(game.id)
    assert game.state == "playing"
  end

  @tag :docker_executor
  test "good code, player won", %{
    game_params: game_params,
    socket1: socket1,
    socket2: socket2
  } do
    {:ok, game} = Game.Context.create_game(game_params)
    game_topic = "game:" <> to_string(game.id)

    {:ok, _response, socket1} = subscribe_and_join(socket1, GameChannel, game_topic)
    {:ok, _response, _socket2} = subscribe_and_join(socket2, GameChannel, game_topic)
    Mix.Shell.Process.flush()

    Phoenix.ChannelTest.push(socket1, "editor:data", %{editor_text: "test", lang_slug: "js"})

    Phoenix.ChannelTest.push(socket1, "check_result", %{
      editor_text:
        "using System; namespace app { public class Solution { public int solution(int a, int b) { return a + b; } } }",
      lang_slug: "csharp"
    })

    assert_code_check()

    assert_receive %Broadcast{
      payload: %{solution_status: true, state: "game_over"}
    }

    game = Game.Context.get_game!(game.id)

    assert game.state == "game_over"
  end

  @tag :docker_executor
  test "test all data cases", %{
    game_params: game_params,
    socket1: socket1,
    socket2: socket2
  } do
    task = insert(:task_with_all_data_types)
    {:ok, game} = Game.Context.create_game(%{game_params | task: task})
    game_topic = "game:" <> to_string(game.id)

    {:ok, _response, socket1} = subscribe_and_join(socket1, GameChannel, game_topic)
    {:ok, _response, _socket2} = subscribe_and_join(socket2, GameChannel, game_topic)
    Mix.Shell.Process.flush()

    Phoenix.ChannelTest.push(socket1, "editor:data", %{editor_text: "test", lang_slug: "js"})

    Phoenix.ChannelTest.push(socket1, "check_result", %{
      editor_text:
        "using System;using System.Collections.Generic; \n
      namespace app{ public class Solution { public List<string> solution(int a, string b, double c, bool d, Dictionary<string, string> e, List<string> f, List<List<string>> g) { return new List<string>(){\"asdf\"}; } } }",
      lang_slug: "csharp"
    })

    assert_code_check()

    # assert_receive %Phoenix.Socket.Broadcast{
    # payload: %{solution_status: true, state: "game_over"}
    # }

    game = Game.Context.get_game!(game.id)

    assert game.state == "game_over"
  end
end
