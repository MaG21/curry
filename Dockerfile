FROM ubuntu:16.04
MAINTAINER Jorge Marizan <jorge.marizan@gmail.com>

# Install the locale generator first
RUN apt-get update
RUN apt-get install -y locales

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install packages
RUN apt-get install -y software-properties-common python-software-properties
RUN add-apt-repository -y ppa:brightbox/ruby-ng
RUN apt-get update
RUN apt-get install -y ruby2.2 ruby2.2-dev git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev nodejs
RUN gem2.2 install bundler
ADD ./ /curry
WORKDIR /curry
RUN bundle install
EXPOSE 8080
ENTRYPOINT ["ruby2.2", "curry.rb", "8080"]




