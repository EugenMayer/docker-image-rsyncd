FROM alpine:edge

# initially created by https://github.com/Duske - thank you!
RUN apk add --no-cache --repository http://dl-4.alpinelinux.org/alpine/edge/testing/ shadow \
	&& apk --update add bash  supervisor rsync tzdata \
	&& rm -f /etc/rsyncd.conf

############# ############# #############
############# SHARED        #############
############# ############# #############

# These can be overridden later
ENV TZ="Europe/Helsinki" \
    LANG="C.UTF-8" \
    UNISON_DIR="/data" \
    HOME="/root"

COPY entrypoint.sh /entrypoint.sh

RUN mkdir -p /docker-entrypoint.d \
 && chmod +x /entrypoint.sh \
 && mkdir -p /etc/supervisor.conf.d

COPY supervisord.conf /etc/supervisord.conf
COPY supervisor.daemon.conf /etc/supervisor.conf.d/supervisor.daemon.conf

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord"]
############# ############# #############
############# /SHARED     / #############
############# ############# #############

EXPOSE 873
