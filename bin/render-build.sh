#!/usr/bin/env bash
set -o errexit

echo "Starting Render build..."

echo "Installing gems..."
bundle install

echo "Precompiling assets..."
bundle exec rails assets:precompile

echo "Running database migrations..."
bundle exec rails db:migrate

echo "Build complete!"

