# Quickstart

1. Install libjansson, Cython and Python 3
2. Run `make` to build the server.
3. Run `make run` to run the server.
4. Start talking to `ws://localhost:8080/`, e.g. using [telsocket](http://telsocket.org/)

# Testing

Run `make test` to run unit tests. Example of a successful run:

	$ make test
	test_get_game_end (bship_logic.tests.ApiTests)
	get_game_end fails when called inappropriately ... ok

	<lots of "... ok">

	Ran 15 tests in 0.002s

	OK

# Command examples
    > Not JSON
    < {"id": null, "error": {"code": -32700, "message": "JSON parse error", "data": "'[' or '{' expected near 'Not'"}, "jsonrpc": "2.0"}

    > {}
    < {"id": null, "error": {"code": -32600, "message": "Invalid Request", "data": "Object item not found: jsonrpc"}, "jsonrpc": "2.0"}

    > {"jsonrpc": "1.1", "method": "newGame", "id": 5666}
    < {"id": 5666, "error": {"code": -32600, "message": "Invalid Request", "data": "JSON-RPC version not 2.0"}, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "newGame", "id": 5667}
    < {"id": 5667, "result": [0, 0], "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "joinGame", "id": 111, "params": [1]}
    < {"id": 111, "error": {"code": -1, "message": "No such game", "data": null}, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "joinGame", "id": 111, "params": [5]}
    < {"id": 111, "result": 8, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "submitGrid", "id": 222}
    < {"id": 222, "error": {"code": -32602, "message": "Invalid params", "data": "Expected 2 params"}, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "submitGrid", "id":223, "params":[7, []]}
    < {"id": 223, "error": {"code": -32602, "message": "Invalid params", "data": "Second parameter must be a 5-element array"}, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "submitGrid", "id":224, "params":[7, [[],[],[],[],[]]]}
    < {"id": 224, "error": {"code": -32602, "message": "Invalid params", "data": "Array index 0 out of range"}, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "submitGrid", "id":225, "params":[7, [[0,0, 1,1], [2,2, 3,3], [4,4, 5,5], [6,6, 8,8], [10,10, 15,10]]]}
    < {"id": 225, "result": null, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "submitGrid", "id": 223, "params": [7, ""]}
    < {"id": 223, "result": null, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "bombPosition", "id": 333, "params":[0, 1, 1]}
    < {"id": 333, "error": {"code": -4, "message": "Invalid player ID", "data": null}, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "bombPosition", "id": 334, "params":[7, -1, 0]}
    < {"id": 334, "error": {"code": -5, "message": "Invalid bomb target", "data": null}, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "bombPosition", "id": 335, "params":[7, 0, 0]}
    < {"id": 335, "result": false, "jsonrpc": "2.0"}

    > {"jsonrpc": "2.0", "method": "getGameEnd", "id": 444, "params":[7]}
    < {"id": 444, "result": {"game_over": false, "won": false, "grid": null}, "jsonrpc": "2.0"}

    > [{"jsonrpc": "2.0", "method": "newGame", "id": 50}, {"aa":"b"}]
    < {"id": null, "error": {"code": -32600, "message": "Invalid Request", "data": "Object item not found: jsonrpc"}}
    < {"id": 50, "result": [1269802784, 670415459]}

Note the last example is not standards-compliant. The backend replies
to a K-element batch request by sending K independent responses
instead of a K-element array of responses.
