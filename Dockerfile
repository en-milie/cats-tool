FROM eclipse-temurin:25-jre-alpine

COPY ./tools/cats/cats.jar /app/app.jar
COPY ./tools/cats/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]