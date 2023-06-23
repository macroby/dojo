Instructions for setting up the repo:

```
# Initial setup

mix deps.get --only prod

MIX_ENV=prod mix compile

# Compile assets

MIX_ENV=prod mix assets.deploy

# Generate release files

mix phx.gen.release

# ...
mix phx.new my_app
cd my_app
MIX_ENV=prod mix release
scp _build/dev/rel/my_app-0.1.0.tar.gz $PROD:/srv/my_app.tar.gz
ssh $PROD "untar -xz /srv/my_app.tar.gz"
ssh $PROD "/srv/my_app/bin/my_app start_daemon

# Finally run the server

MIX_ENV=prod PORT=4001 elixir --erl "-detached" -S mix phx.server
```

go into the /assets directory and install npm packages:

npm install

npm run res:build

return to root directory and run:

mix deps.get

make sure to place stockfish executable at the root of the server directory with name "stockfish"

start server with:

mix phx.server