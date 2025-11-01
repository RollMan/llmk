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

FROM devenv AS ctanpkg_dep
# Dependencies to typeset doc/llmk.tex
RUN tlmgr install \
    booktabs \
    bxtexlogo \
    datetime \
    enumitem \
    fancyvrb \
    fmtcount \
    fontspec \
    greek-fontenc \
    hologo \
    inconsolata \
    koma-script \
    listings \
    needspace \
    newunicodechar \
    pgf \
    stix2-otf \
    tex-gyre \
    texfot \
    unicode-math \
    utfsym \
    xcolor \
    xkeyval \
    xunicode \
    ;
RUN fc-cache -fv && \
    ln -s /opt/texlive/2025/texmf-var/fonts/conf/texlive-fontconfig.conf /etc/fonts/conf.d/09-texlive.conf
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get --no-install-recommends install -y zip

FROM ctanpkg_dep AS ctanpkg_build
RUN --mount=type=bind,source=.,target=.,rw=true \
    cp llmk.lua /usr/bin/llmk && \
    chmod +x /usr/bin/llmk
RUN --mount=type=cache,target=/root/.gem \
    --mount=type=bind,source=.,target=.,rw=true \
    bundle exec rake ctan && \
    mkdir -p /obj && \
    cp ./llmk-1.2.1.zip /obj

FROM scratch AS ctanpkg
COPY --link --from=ctanpkg_build /obj /
