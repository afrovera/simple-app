FROM openjdk:8-jre-alpine
ADD target/spring-boot-docker.jar spring-boot-docker.jar
EXPOSE 80
ENTRYPOINT ["java", "-jar", "spring-boot-docker.jar"]
COPY ./${JAR_FILE} app.jar
