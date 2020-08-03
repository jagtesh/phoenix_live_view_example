FROM elixir:latest AS stage1

WORKDIR /stage1
ENV MIX_ENV=dev

RUN apt-get update && \
  # apt-get install -y postgresql-client && \
  apt-get install -y inotify-tools && \
  apt-get install -y nodejs && \
  curl -L https://npmjs.org/install.sh | sh && \
  mix local.hex --force && \
  # mix archive.install hex phx_new 1.5.3 --force && \
  mix local.rebar --force

COPY . /stage1
RUN mix deps.get && \
  npm install --prefix /stage1/assets

RUN npm run deploy --prefix /stage1/assets && \
  mix compile && \
  mix phx.digest && \
  mix release

FROM postgres:13 AS stage2

WORKDIR /app
ENV DATABASE_URL=postgres://postgres@localhost:demo_dev

COPY --from=stage1 /stage1/_build/dev /app
# Release created at _build/dev/rel/prod!
#     # To start your system
#     _build/dev/rel/prod/bin/prod start
#
# Once the release is running:
#     # To connect to it remotely
#     _build/dev/rel/prod/bin/prod remote
#     # To stop it gracefully (you may also send SIGINT/SIGTERM)
#     _build/dev/rel/prod/bin/prod stop
#
# To list all commands:
#     _build/dev/rel/prod/bin/prod

CMD ["./rel/prod/bin/prod start"]
