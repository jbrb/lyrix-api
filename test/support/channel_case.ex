defmodule RequesterWeb.ChannelCase do
  Ecto.Adapters.SQL.Sandbox
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest

      # The default endpoint for testing
      @endpoint RequesterWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Requester.Repo)
    unless tags[:async] do
      Sandbox.mode(Requester.Repo, {:shared, self()})
    end
    :ok
  end

end
