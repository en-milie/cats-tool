FROM eclipse-temurin:25-jre-alpine

RUN mkdir -p /tool /specifications

COPY cats.jar /tool/cats.jar
COPY config.sh /tool/config.sh

COPY ./apis/*/specifications/* /specifications/

CMD ["/bin/sh", "-c", "\
  sh /tool/config.sh && cd /tool && \
  while true; do \
    java -jar cats.jar \
      --contract /specifications/${API}-openapi.json \
      --server http://${HOST}:${PORT} \
      -b -k \
      --includeEmojis \
      --includeControlChars \
      --includeWhitespaces; \
  done"]
