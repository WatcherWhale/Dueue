FROM elixir:1.16.1 AS release_stage

COPY mix.exs .
COPY mix.lock .
RUN mix deps.get
RUN mix deps.compile

COPY lib ./lib

ENV MIX_ENV=prod
RUN mix release

FROM elixir:1.16.1 AS run_stage

COPY --from=release_stage $HOME/_build .
CMD ["./prod/rel/dueue/bin/dueue", "start"]
