FROM archlinux

# docker build . && docker run --rm -ti -v $PWD/build:/build $(docker build -q .) -c "cat /src/apps/openssl" > openssl-x64

ENV OPENSSL_VERSION 1.1.1q

RUN pacman -Sy --noconfirm archlinux-keyring && pacman -Syu --noconfirm \
  base \
  base-devel

ADD https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz /
run tar -xzf /openssl-${OPENSSL_VERSION}.tar.gz && \
  mv openssl-${OPENSSL_VERSION} src


WORKDIR /src
RUN ./Configure linux-x86_64 -static 
RUN make -j16

ENTRYPOINT ["/bin/sh"]
