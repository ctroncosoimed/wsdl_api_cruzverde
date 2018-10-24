FROM ruby:2.5

RUN mkdir -p /cruzverdeapi
WORKDIR /cruzverdeapi


RUN apt-get update && apt-get install -y nodejs postgresql-client vim --no-install-recommends && rm -rf /var/lib/apt/lists/*

COPY Gemfile /cruzverdeapi
COPY Gemfile.lock /cruzverdeapi

RUN bundle config --global frozen 1
RUN bundle install 

COPY . /cruzverdeapi

EXPOSE 4000
CMD ["rails", "server", "-b", "0.0.0.0"]