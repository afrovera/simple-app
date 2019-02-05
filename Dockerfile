FROM openjdk:8-jdk-alpine
VOLUME /tmp
ARG JAR_FILE
COPY ${JAR_FILE} app.jar
EXPOSE 5000
ENTRYPOINT ["java", "-jar", “app.jar"]
