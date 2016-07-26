defmodule KV.Registry do
	use GenServer

	# Client api
	def start_link(name) do
		GenServer.start_link(__MODULE__, name, name: name)
	end

	def lookup(server, name) when is_atom(server) do
		case :ets.lookup(server, name) do
			[{^name, bucket}] -> {:ok, bucket}
			[] -> :error
		end
	end

	def create(server, name) do
		GenServer.call(server, {:create, name})
	end

	def stop(server) do
		GenServer.stop(server)
	end

	# SErver callbacks

	def init(table) do
		names=:ets.new(table, [:named_table, read_concurrency: true])
		refs=%{}
		{:ok, {names, refs}}

	end

	# def handle_call({:lookup, name}, _from, {names,_}=state) do
	# 	{:reply, Map.fetch(names,name), state}
	# end
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}
      :error ->
        {:ok, pid} = KV.Bucket.Supervisor.start_bucket
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end
  end
	def handle_info({:DOWN, ref, :process, _pid, _reason},{names, refs}) do
		{name, refs} = Map.pop(refs, ref)
		# names = Map.delete(names, name)
		:ets.delete(names, name)
		{:noreply, {names, refs}}
	end
	def handle_info(_msg, state) do
		IO.puts "other message"
		{:noreply, state}
	end

end