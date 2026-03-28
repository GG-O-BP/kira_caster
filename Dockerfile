FROM ghcr.io/gleam-lang/gleam:v1.15.2-erlang-alpine AS build

RUN apk add --no-cache gcc musl-dev sqlite-dev

WORKDIR /app

COPY gleam.toml manifest.toml ./
RUN gleam deps download

COPY src/ src/
RUN gleam build

FROM erlang:28-alpine AS runtime

RUN apk add --no-cache sqlite-libs

WORKDIR /app

COPY --from=build /app/build/dev/erlang /app/build/dev/erlang
COPY --from=build /app/gleam.toml /app/gleam.toml

ENV KIRA_DB_PATH=/app/data/kira_caster.db
ENV KIRA_ADMIN_PORT=8080

EXPOSE 8080

VOLUME ["/app/data"]

CMD ["erl", "-pa", "build/dev/erlang/*/ebin", "-noshell", "-eval", "gleam@@main:run(kira_caster)"]
