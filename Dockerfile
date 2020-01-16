FROM golang:1.13
ENV CGO_ENABLED 1
ENV GOFLAGS '-mod=vendor'
ENV GO_NO_DEBUG ''

RUN apt update && apt install -y inotify-tools
RUN go get github.com/derekparker/delve/cmd/dlv

WORKDIR /app

COPY ./watch.sh /watch.sh

EXPOSE 40000

ENTRYPOINT /watch.sh