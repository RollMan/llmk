# A ruby enviroment to run tests in spec/

FROM ruby:3.4.7-trixie AS test
COPY --from=registry.gitlab.com/islandoftex/images/texlive@sha256:908066279e32537d27597df23d6b10522ad00cbfee23f08beed5f57232f90bf6 --link /usr /opt/texlive
WORKDIR /work
ENV PATH=$PATH:/opt/texlive/bin

# Assert an environment variable of "GITHUB_ACTIONS" to enable local test.
# It seems like tests do not use something available only in GITHUB_ACTIONS.
ENV GITHUB_WORKFLOW=1
RUN --mount=type=cache,target=/root/.gem \
    --mount=type=bind,source=.,target=/work,rw=true \
    gem update --system --no-document --conservative && \
    bundle config path vendor/bundle && \
    bundle install --jobs 4 --retry 3 && \
    bundle exec rake setup_unix && \
    # TODO: make another layer for the above commands that set up environemnts.
    bundle exec rake test
