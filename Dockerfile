# A ruby enviroment to run tests in spec/

FROM ruby:3.4.7-trixie AS test
WORKDIR /work
ENV PATH=$PATH:/tmp/texlive/bin/x86_64-linux
# Assert an environment variable of "GITHUB_ACTIONS" to enable local test.
# It seems like tests do not use something available only in GITHUB_ACTIONS.
ENV GITHUB_ACTIONS=1

RUN --mount=type=cache,target=/root/.gem \
    --mount=type=bind,source=.,target=/work,rw=true \
    bundle config path /vendor/bundle && \
    bundle install --jobs 4 --retry 3
RUN --mount=type=cache,target=/root/.gem \
    --mount=type=bind,source=.,target=/work,rw=true \
    bundle exec rake setup_unix
RUN --mount=type=cache,target=/root/.gem \
    --mount=type=bind,source=.,target=/work,rw=true \
    bundle exec rake test
