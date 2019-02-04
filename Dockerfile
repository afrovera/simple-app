FROM openjdk:8-jdk-alpine
FROM openjdk:8-jdk-alpine
VOLUME /tmp
ADD JAR_FILE
COPY ${JAR_FILE} app.jar
RUN sh -c 'touch /app.jar'
ENV JAVA_OPTS=""
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar" ]
EXPOSE 80
