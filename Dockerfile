# A ruby enviroment to run tests in spec/

FROM ruby:3.4.7-trixie AS devenv
# Copy texlive of scheme-base.
# Later install uplatex and xelatex indivisually because
# schemes including both of uptex and xelatex installs
# so many redundant packages for this test purpose.
COPY --link --from=registry.gitlab.com/islandoftex/images/texlive@sha256:908066279e32537d27597df23d6b10522ad00cbfee23f08beed5f57232f90bf6 /usr/local/texlive/ /opt/texlive/
WORKDIR /work
# Set PATH to texlive executable.
# TODO: support multi-platform with `ARG BUILDARCH`.
# https://docs.docker.com/reference/dockerfile#automatic-platform-args-in-the-global-scope
ENV PATH=$PATH:/opt/texlive/2025/bin/x86_64-linux

# Install xelatex and uplatex
RUN tlmgr install \
    gsftopk \
    haranoaji \
    ptex-fontmaps \
    uplatex \
    uptex \
    xetex \
    ;

RUN --mount=type=cache,target=/root/.gem \
    --mount=type=bind,source=./Gemfile,target=./Gemfile \
    --mount=type=bind,source=./Gemfile.lock,target=./Gemfile.lock \
    --mount=type=bind,source=./Rakefile,target=./Rakefile \
    bundle config set frozen true && \
    bundle config path /vendor/bundle && \
    bundle install --jobs 4 --retry 3

FROM devenv AS test
RUN --mount=type=cache,target=/root/.gem \
    --mount=type=bind,source=.,target=.,rw=true \
    bundle exec rake test

FROM devenv AS ctanpkg_build
RUN --mount=type=cache,target=/root/.gem \
    --mount=type=bind,source=.,target=.,rw=true \
    bundle exec rake ctan

FROM ctanpkg_build AS ctanpkg
COPY --link --from=devenv /work/llmk-1.2.1.zip /
