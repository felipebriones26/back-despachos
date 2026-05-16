FROM maven:3.9.6-eclipse-temurin-17-alpine AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

RUN addgroup -S devopsgroup && adduser -S devopsuser -G devopsgroup
COPY --from=build /app/target/*.jar app.jar
RUN chown -R devopsuser:devopsgroup /app
USER devopsuser

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]