# gomon-docker
Docker image for golang development with hot-reload

This image allows to run golang inside container with possibility to:

1. Debug (using [Delve](https://github.com/go-delve/delve))
2. Autorefresh/autorestart using [inotify](https://linux.die.net/man/1/inotifywatch)

## Quirks

1. Due to some specifics which were needed, `GOFLAGS` is set to `'-mod=vendor'`. This could be overwritten using `docker-compose` file
2. `WORKDIR` is set to `/app` so watcher expects source code to be located under workdir. (Just map your code to `/app` using `docker-compose`)
3. Signalling - when running in debug mode, -9 (kill) is send to debugger and application. When running in `GO_NO_DEBUG=true` mode, TERM signal is sent to application
4. Files watching - right now only files with extension `go` are monitored. Next versions would probably include some ENV for this
5. Delve api version 2 is used 

## Env

The following env variables are available:
* `PACKAGE_DIR` - package where the main file located if not in root. Example: `./cmd/run`. Defaults to `.`
* `GO_NO_DEBUG` - set it to anything except empty value to disable debugging, leaving only hot-reload on code changes
* `GOMON_DIED_CHECK_INTERVAL` - (in seconds, default: **2**s) monitor will check if APP is alive with set interval
* `GOMON_IGNORE` - extended regex to exclude files being watched

## Ports

Port 40000 is exposed for delve debugging

## Sample usage

### With debug disabled

```yaml docker-compose.yml
version: '2.1'
services:
  go-dev:
    image: gomon-docker:1.14
    environment:
      GO_NO_DEBUG: "true"
    volumes:
      - .:/app:delegated
    ports:
      - 9080 # your application exposed port
    network_mode: bridge
    restart: always
```

### With debug enabled

```yaml docker-compose.yml
version: '2.1'
services:
  go-dev:
    image: gomon-docker:1.14
    volumes:
      - .:/app:delegated
    ports:
      - 40000:40000 # this is Delve debugging port
      - 9080 # your application exposed port
    network_mode: bridge
    restart: always
```