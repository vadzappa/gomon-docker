FROM golang:1.16
ENV CGO_ENABLED 1
ENV GOFLAGS '-mod=vendor'
ENV GO_NO_DEBUG ''
ENV PACKAGE_DIR '.'

RUN apt update && apt install -y inotify-tools
RUN go get github.com/go-delve/delve/cmd/dlv

WORKDIR /app

COPY ./watch.sh /watch.sh
COPY ./inotifier.sh /inotifier.sh
COPY ./check-alive.sh /check-alive.sh

EXPOSE 40000

ENTRYPOINT ["/watch.sh"]