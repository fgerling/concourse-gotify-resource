FROM alpine

RUN apk add --update bash curl jq && \
  rm -rf /var/cache/apk/*
ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*
