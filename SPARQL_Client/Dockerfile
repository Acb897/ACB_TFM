FROM ruby:2.7.0

ENV LANG="en_US.UTF-8" LANGUAGE="en_US:UTF-8" LC_ALL="C.UTF-8"
RUN chmod a+r /etc/resolv.conf

RUN mkdir /sparqlclient
WORKDIR /sparqlclient
RUN gem update --system
RUN gem install bundler:2.2.19
COPY . /sparqlclient/
RUN bundle install
CMD ["ruby", "sparqlclient.rb", "-o", "0.0.0.0"]

