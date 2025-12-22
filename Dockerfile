FROM eclipse-temurin:25-jre-alpine

COPY ./tools/cats/cats.jar /app/cats.jar
COPY ./tools/cats/entrypoint.sh /app/entrypoint.sh

WORKDIR /app

ENTRYPOINT ["entrypoint.sh"]