#!/usr/bin/env bash
set -o errexit

echo "Starting Render build..."

echo "Installing gems..."
bundle install

echo "Precompiling assets..."
bundle exec rails assets:precompile

echo "Running database migrations..."
bundle exec rails db:migrate
bundle exec rails db:migrate:primary
bundle exec rails db:migrate:cache || echo "Cache migrations skipped"
bundle exec rails db:migrate:queue || echo "Queue migrations skipped"
bundle exec rails db:migrate:cable || echo "Cable migrations skipped"

echo "Build complete!"

