# syntax=docker/dockerfile:1.7
FROM rust:1-bookworm AS builder
WORKDIR /app
ENV CARGO_HTTP_TIMEOUT=600 \
    CARGO_NET_RETRY=10 \
    CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
COPY Cargo.toml Cargo.lock* ./
COPY src ./src
COPY docs ./docs
COPY migrations ./migrations
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/app/target,sharing=locked \
    cargo build --release && cp /app/target/release/feedbackflow-server /app/feedbackflow-server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/feedbackflow-server /app/feedbackflow-server
COPY migrations /app/migrations
ENV APP_HOST=0.0.0.0 APP_PORT=8080
EXPOSE 8080
CMD ["/app/feedbackflow-server"]
