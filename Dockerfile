# Stage 1
# Build frontend assets
FROM node:latest AS stage1

WORKDIR /stage1

COPY . /stage1
RUN npm install --prefix ./assets && \
  npm run deploy --prefix ./assets


# Stage 2
# Create elixir release package
FROM elixir:latest AS stage2

WORKDIR /stage2
ENV MIX_ENV=dev

COPY --from=stage1 . /stage2
RUN mix local.hex -y
RUN mix deps.get && \
  mix compile && \
  mix phx.digest && \
  mix release


# Stage 3 (optional - for testing only)
# Install postgres and copy release to /app
FROM postgres:13 AS stage3

WORKDIR /app
ENV DATABASE_URL=postgres://postgres@localhost:demo_dev

COPY --from=stage2 /stage2/_build/dev /app
RUN createdb demo_dev

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
