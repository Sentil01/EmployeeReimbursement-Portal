#!/usr/bin/env bash
set -o errexit

echo "Starting Render build..."

echo "Installing gems..."
bundle install

echo "Precompiling assets..."
bundle exec rails assets:precompile

echo "Running database migrations..."
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails db:migrate:cache || true
RAILS_ENV=production bundle exec rails db:migrate:queue || true
RAILS_ENV=production bundle exec rails db:migrate:cable || true

echo "Build complete!"

