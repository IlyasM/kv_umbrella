exclude= 
	if Node.alive?, do: [], else: [distributed: true]
ExUnit.start(exclude)
ExUnit.configure exclude: :pending, trace: true
