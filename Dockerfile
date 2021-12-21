FROM golang:1.17
ENV CGO_ENABLED 1
ENV GO_NO_DEBUG ''
ENV PACKAGE_DIR '.'

RUN apt update && apt install -y inotify-tools
RUN go install github.com/go-delve/delve/cmd/dlv@latest

WORKDIR /app

COPY ./watch.sh /watch.sh
COPY ./inotifier.sh /inotifier.sh
COPY ./check-alive.sh /check-alive.sh

EXPOSE 40000

ENTRYPOINT ["/watch.sh"]