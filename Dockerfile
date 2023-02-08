FROM curlimages/curl AS basecurl

USER root
WORKDIR /opt
ARG SONARQUBE_VERSION=9.9.0.65466
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
RUN set -x \
    && curl -o sonarqube.zip -fSL $SONARQUBE_ZIP_URL
USER "${USER_UID}"

FROM eclipse-temurin:17-jre
USER root
ARG SONARQUBE_VERSION=9.9.0.65466
ENV JAVA_HOME='/opt/java/openjdk' \
    SONARQUBE_HOME=/opt/sonarqube \
    SONAR_VERSION="${SONARQUBE_VERSION}" \
    SQ_DATA_DIR="/opt/sonarqube/data" \
    SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
    SQ_LOGS_DIR="/opt/sonarqube/logs" \
    SQ_TEMP_DIR="/opt/sonarqube/temp"

# Http port
EXPOSE 9000

#Ajuste de SonarQube local sobre las carpetas de la imagen
RUN groupadd -r sonarqube && useradd -r -g sonarqube sonarqube

WORKDIR /opt

COPY --from=basecurl /opt/sonarqube.zip .
RUN set -eux; \
    unzip sonarqube.zip; \
    mv "sonarqube-${SONARQUBE_VERSION}" sonarqube; \
    chown -R sonarqube:sonarqube sonarqube; \
    rm sonarqube.zip; \
    rm -rf ${SONARQUBE_HOME}/bin/*; \
    ln -s "${SONARQUBE_HOME}/lib/sonar-application-${SONARQUBE_VERSION}.jar" "${SONARQUBE_HOME}/lib/sonarqube.jar"; \
    chmod -R 555 ${SONARQUBE_HOME}; \
    chmod -R ugo+wrX "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"; \
    touch $SONARQUBE_HOME/logs/es.log

#Datos persistentes
VOLUME "$SONARQUBE_HOME/data"

#Operamos sobre los binarios en el folder final
WORKDIR $SONARQUBE_HOME

COPY entrypoint.sh ${SONARQUBE_HOME}/docker/

WORKDIR ${SONARQUBE_HOME}
EXPOSE 9000

USER sonarqube
STOPSIGNAL SIGINT

ENTRYPOINT ["/opt/sonarqube/docker/entrypoint.sh"]
