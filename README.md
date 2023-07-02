go into the /assets directory and install npm packages:

npm install

npm run res:build

return to root directory and run:

mix deps.get

make sure to place stockfish executable at the root of the server directory with name "stockfish"

start server with:

MIX_ENV=prod elixir --erl "-detached" -S mix phx.server