FROM archlinux

ARG OPENSSL_VERSION=1.1.1q

ENV ANDROID_NDK_HOME /ndk
ENV PATH "/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}"

RUN pacman -Sy --noconfirm archlinux-keyring && pacman -Syu --noconfirm \
  base \
  base-devel \
  qemu-user

ADD build.sh /
RUN chmod +x /build.sh

USER nobody

ADD --chown=nobody:nobody https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz /tmp/
RUN tar -xzf /tmp/openssl-${OPENSSL_VERSION}.tar.gz -C /tmp/

WORKDIR /tmp/openssl-${OPENSSL_VERSION}

CMD /build.sh
