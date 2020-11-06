FROM gradle:4.8.0-jdk8-alpine AS build
LABEL backend_app="0.0.1"

ARG BACKEND_URL=https://github.com/nobumori/devops-training-project-frontend.git
WORKDIR /opt
USER root
RUN apk --verbose --update-cache --upgrade add \
    git \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && git clone ${BACKEND_URL} ${WORKDIR} \
    && cd devops-training-project-backend \
    && ./gradlew --quiet --no-daemon --no-build-cache build -x test 
 
FROM openjdk:8-jre-alpine AS production

ENV BUILD_PATH=/opt/devops-training-project-backend/build
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
WORKDIR /opt/backend
COPY --chown=0:0 --from=build ${BUILD_PATH}/libs/* ${WORKDIR}
COPY --chown=0:0 --from=build ${BUILD_PATH}/resources/main/application.properties ${WORKDIR}
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost:8080/tags || exit 1
EXPOSE 8080
CMD ["java", \
     "-Dspring.config.location=./", \
     "-jar", \
     "devops-training-project-backend.jar"    ]