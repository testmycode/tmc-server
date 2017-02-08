bundle install --retry=3 --jobs=3 --deployment

# Git settings so that Jenkins can clone submodules
sed -i 's/git@github.com:/https:\/\/github.com\//' .gitmodules
git submodule update --init --recursive

git config --global user.email "jenkins@example.com"
git config --global user.name "Jenkins"

# Build submodules except sandbox
bundle install --retry=3 --jobs=3
bundle exec rake compile

bundle exec rake db:drop
env RAILS_ENV=test bundle exec rake db:create db:migrate

# Run tests
bundle exec rake spec SPEC_OPTS="--format documentation" \
SANDBOX_HOST=127.0.0.1 \
SANDBOX_PORT=57001

