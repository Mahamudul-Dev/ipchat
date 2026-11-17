# Stage 1: Build the native binary using official Dart SDK
FROM dart:stable AS build

WORKDIR /app

# Copy dependency specifications and resolve dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy all source files and compile the relay to a standalone executable
COPY . .
RUN dart compile exe bin/relay.dart -o /app/bin/relay

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim

WORKDIR /app

# Install ca-certificates and minimal libraries required by Dart native runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy pre-compiled binary from build stage
COPY --from=build /app/bin/relay /app/relay

# Make binary executable
RUN chmod +x /app/relay

# Stealth Port for QUIC/HTTP3 disguise
EXPOSE 443/udp

ENV PORT=443

ENTRYPOINT ["/app/relay"]
