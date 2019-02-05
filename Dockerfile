FROM openjdk:8-jdk-alpine
VOLUME /tmp
ADD target/suchapp-0.0.1-SNAPSHOT.jar suchapp-0.0.1-SNAPSHOT.jar
EXPOSE 5000
CMD ["java", "-jar", "suchapp-0.0.1-SNAPSHOT.jar"]
