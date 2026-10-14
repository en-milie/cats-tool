# Pinned to a digest, since a tag moves to the newest build of the Java release
FROM eclipse-temurin:25-jre-alpine@sha256:3c0a9084927a221ccd1d007fcaf614465672c0af37aaa834c5184483afe56d61

COPY ./tools/cats/cats.jar /app/app.jar
COPY ./tools/cats/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]