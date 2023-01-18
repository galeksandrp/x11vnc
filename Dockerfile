FROM alpine:3.16.2 AS builder
RUN apk add --update alpine-sdk
RUN adduser -D ng -G abuild
COPY --chown=ng:abuild alpine /home/ng/abuild
USER ng
WORKDIR /home/ng/abuild
RUN abuild-keygen -n -a
RUN abuild checksum
RUN abuild deps
RUN abuild

FROM alpine:3.16.2 AS installer
COPY --from=builder /home/ng/.abuild/*.rsa.pub /etc/apk/keys
COPY --from=builder /home/ng/packages /root/packages
RUN echo '@ng /root/packages/ng' >> /etc/apk/repositories
RUN apk add --no-cache x11vnc@ng

FROM installer AS solib
RUN apk add --no-cache linux-headers \
  build-base
RUN Xdummy -install

FROM installer
RUN apk add --no-cache xvfb xorg-server \
  xf86-video-dummy
RUN wget -O /usr/share/X11/xorg.conf.d/20-xdummy.conf https://raw.githubusercontent.com/Xpra-org/xpra/master/fs/etc/xpra/xorg.conf
COPY --from=solib /usr/bin/Xdummy.so /usr/bin/Xdummy.so
CMD ["x11vnc", "-create", "-setdesktopsize"]
