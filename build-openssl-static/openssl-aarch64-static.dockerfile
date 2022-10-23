FROM archlinux

# docker build . && docker run --rm -ti -v $PWD/build:/build $(docker build -q .) -c "cat /src/apps/openssl" > openssl-arm64

ENV OPENSSL_VERSION 1.1.1q

ENV AR aarch64-linux-gnu-ar
ENV CC aarch64-linux-gnu-gcc
ENV AS $CC
ENV CXX aarch64-linux-gnu-c++
ENV LD aarch64-linux-gnu-ld
ENV RANLIB aarch64-linux-gnu-ranlib
ENV STRIP aarch64-linux-gnu-strip

RUN pacman -Sy --noconfirm archlinux-keyring && pacman -Syu --noconfirm \
  base \
  base-devel \
  aarch64-linux-gnu-binutils \
  aarch64-linux-gnu-glibc

ADD https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz /
run tar -xzf /openssl-${OPENSSL_VERSION}.tar.gz && \
  mv openssl-${OPENSSL_VERSION} src


WORKDIR /src
RUN ./Configure linux-aarch64 -static 
RUN make -j16

ENTRYPOINT ["/bin/sh"]
