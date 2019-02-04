FROM openjdk:8-jdk-alpine
# Install dependencies
RUN mvn -B dependency:resolve dependency:resolve-plugins
VOLUME /tmp
ARG JAR_FILE
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
EXPOSE 80
