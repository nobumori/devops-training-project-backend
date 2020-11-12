FROM gradle:4.8.0-jdk8-alpine AS test
ARG DB_NAME=DUMMY_DB_NAME 
ARG DB_PASSWORD=DUMMY_DB_PASSWORD 
ARG DB_PORT=DUMMY_DB_PORT
ARG DB_URL=DUMMY_DB_URL 
ARG DB_USERNAME=DUMMY_DB_USERNAME
WORKDIR /opt
USER root
RUN apk --verbose --update-cache --upgrade add \
    git \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* 
COPY --chown=0:0 . .   
RUN gradle --quiet --no-daemon --no-build-cache build test 

FROM gradle:4.8.0-jdk8-alpine AS build
WORKDIR /opt
USER root
RUN apk --verbose --update-cache --upgrade add \
    git \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* 
COPY --chown=0:0 . .   
RUN gradle --quiet --no-daemon --no-build-cache build -x test 
 
FROM openjdk:8-jre-alpine AS production
LABEL backend_app="0.0.1"
ENV BUILD_PATH=/opt/build
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
