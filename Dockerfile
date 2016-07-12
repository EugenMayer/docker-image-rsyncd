FROM alpine
# initially created by https://github.com/Duske - thank you!
MAINTAINER Eugen Mayer <eugen.mayer@kontextwork.de>
RUN apk --update add rsync

EXPOSE 873

COPY ./run /usr/local/bin/run

ENTRYPOINT ["/usr/local/bin/run"]
