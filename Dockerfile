# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.3.6
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RUBY_YJIT_ENABLE="1"

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Fix WSL permission issues and create missing directories
RUN chmod +x bin/* && \
    mkdir -p log storage tmp/pids tmp/cache tmp/sockets app/assets/builds && \
    SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create directories and set permissions
RUN mkdir -p /rails/log /rails/storage /rails/tmp/pids /rails/tmp/cache /rails/tmp/sockets && \
    groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails/db /rails/log /rails/storage /rails/tmp
USER 1000:1000

ENTRYPOINT ["bash", "/rails/bin/docker-entrypoint"]

# Railway sets PORT dynamically; Puma reads it from ENV
EXPOSE 3000

# Health check for Railway
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:${PORT:-3000}/up || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
