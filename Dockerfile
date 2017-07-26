FROM elixir:1.4.5

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y wget curl inotify-tools git build-essential zip unzip && \
    apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install hex package manager
RUN mix local.hex --force

# Install rebar (Erlang build tool)
RUN mix local.rebar --force

# Install the Phoenix framework itself
RUN mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez

# Install Node and NPM
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y -q nodejs

WORKDIR /app

# install mix deps
ADD ./mix.exs /app
ADD ./mix.lock /app
RUN mix deps.get

# install npm deps
ADD ./package.json /app
ADD ./package-lock.json /app
RUN npm install

RUN mix compile

ADD . /app

