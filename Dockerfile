FROM alpine:latest

RUN \
  apk --no-cache add \
    autossh \
    net-tools \
    dumb-init && \
  chmod g+w /etc/passwd

ENV \
  AUTOSSH_PIDFILE=/tmp/autossh.pid \
  AUTOSSH_POLL=30 \
  AUTOSSH_GATETIME=30 \
  AUTOSSH_FIRST_POLL=30 \
  AUTOSSH_LOGLEVEL=0 \
  AUTOSSH_LOGFILE=/dev/stdout

COPY /entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
