#!/usr/bin/env bash
# exit on error
set -o errexit
# Disable frozen Gemfile.lock
bundle config set frozen 'false'

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
bundle exec rails db:seed