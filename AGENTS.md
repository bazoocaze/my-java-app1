# my-java-app

## Tech Stack

- **Java 21** — language version
- **Spring Boot 3.4.4** with `spring-boot-starter-web` + `spring-boot-starter-actuator`
- **Maven** — build tool
- **Docker** — multi-stage build with BuildKit cache mounts
- **Helm v2** — Kubernetes packaging (Deployment + Service ClusterIP, no Ingress, no HPA)

## Project Structure

```
my-java-app/
├── pom.xml                              # Java 21, Spring Boot 3.4.4
├── AGENTS.md                            # this file
├── .gitignore                           # target/, .idea/, *.iml, *.swp
├── src/main/java/com/example/
│   ├── Application.java                 # @SpringBootApplication
│   └── HelloController.java             # GET /hello → "Hello, World!"
├── src/main/resources/
│   └── application.yml                  # server.port=8080, actuator /health
├── docker/
│   └── Dockerfile                       # multi-stage (maven build → jre runtime)
├── local/
│   ├── build.sh                         # mvn clean package
│   ├── run.sh                           # mvn spring-boot:run
│   └── docker.sh                        # docker build + run
└── helm/
    ├── Chart.yaml
    ├── values.yaml
    ├── .helmignore
    └── templates/
        ├── _helpers.tpl
        ├── deployment.yaml              # liveness+readiness via /actuator/health
        └── service.yaml                 # ClusterIP port 8080
```

## Key Commands

```bash
# Build JAR
./local/build.sh

# Run locally
./local/run.sh

# Docker build + run
./local/docker.sh

# Or directly with Maven
mvn spring-boot:run

# Helm lint
helm lint helm/

# Helm install (local k8s)
helm install my-java-app helm/
```

## Docker Build Cache

The Dockerfile uses BuildKit `--mount=type=cache,target=/root/.m2` to persist the Maven repository across builds. The cache is stored internally by BuildKit (not a Docker volume). It is **shared across all projects** on the same machine that use the same cache target path. To isolate per project, an `id` parameter can be added:

```
--mount=type=cache,id=maven-<project>,target=/root/.m2
```

## Endpoints

- `GET /hello` → `"Hello, World!"`
- `GET /actuator/health` → health check (liveness/readiness probes)

## Design Decisions

- **Actuator** included specifically for Kubernetes health probes (`/actuator/health`)
- **No Ingress** — only ClusterIP Service (tested via `port-forward` or `minikube service`)
- **No HPA** — not needed for local testing
- **IntelliJ IDEA** — `.idea/` and `*.iml` in `.gitignore`
- **`<finalName>`** uses `${project.artifactId}` (not the deprecated `${artifactId}`)