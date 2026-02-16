#!/bin/bash
# AltarServe Manager - Development Environment Setup Script
# WSL2 Ubuntu 24.04 + Ruby 3.2 + PostgreSQL 16 + Rails 8
set -e

echo "=== AltarServe Manager Dev Environment Setup ==="

# 1. Build dependencies
echo "[1/6] Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  build-essential git curl libssl-dev libreadline-dev zlib1g-dev \
  autoconf bison libyaml-dev libncurses5-dev libffi-dev libgdbm-dev \
  libpq-dev libvips

# 2. PostgreSQL 16
echo "[2/6] Installing PostgreSQL 16..."
sudo apt-get install -y -qq postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Create dev database user
sudo -u postgres createuser -s $(whoami) 2>/dev/null || true
echo "PostgreSQL user '$(whoami)' created (or already exists)"

# 3. rbenv + Ruby 3.2
echo "[3/6] Installing rbenv + Ruby 3.2..."
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init -)"

if ! rbenv versions | grep -q "3.2"; then
  RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl 2>/dev/null || echo /usr)" \
    rbenv install 3.2.7
fi
rbenv global 3.2.7
rbenv rehash

echo "Ruby version: $(ruby --version)"

# 4. Bundler + Rails
echo "[4/6] Installing Bundler and Rails 8..."
gem install bundler --no-document
gem install rails --version '~> 8.0' --no-document
rbenv rehash

echo "Rails version: $(rails --version)"

# 5. Redis (optional, not required for Rails 8 Solid Trifecta)
echo "[5/6] Skipping Redis (Rails 8 uses Solid Queue/Cache/Cable - DB-backed)"

# 6. Project setup
echo "[6/6] Setting up Rails project..."
cd /mnt/c/workspace/sungsan

if [ -f "Gemfile" ]; then
  bundle install
  bin/rails db:create db:migrate db:seed
  echo "=== Project setup complete! ==="
else
  echo "=== Environment ready. Run 'rails new' or check the project files. ==="
fi

echo ""
echo "=== Setup Complete ==="
echo "Ruby: $(ruby --version)"
echo "Rails: $(rails --version)"
echo "PostgreSQL: $(psql --version)"
echo ""
echo "Next steps:"
echo "  cd /mnt/c/workspace/sungsan"
echo "  bundle install"
echo "  bin/rails db:create db:migrate db:seed"
echo "  bin/rails server"
