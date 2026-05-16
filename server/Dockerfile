FROM rust:1-bookworm AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock* ./
COPY src ./src
COPY migrations ./migrations
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/feedbackflow-server /app/feedbackflow-server
COPY migrations /app/migrations
ENV APP_HOST=0.0.0.0 APP_PORT=8080
EXPOSE 8080
CMD ["/app/feedbackflow-server"]
