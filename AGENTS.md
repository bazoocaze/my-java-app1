# my-java-app

## Tech Stack

- **Java 21** — language version
- **Spring Boot 3.4.4** with `spring-boot-starter-web` + `spring-boot-starter-actuator`
- **Maven** — build tool
- **Docker** — multi-stage build with BuildKit cache mounts
- **Helm v2** — Kubernetes packaging (Deployment + Service ClusterIP, no Ingress, no HPA)
- **GitHub Actions** — CI pipeline: Maven build, Docker build (with GHA cache), Helm lint

## Project Structure

```
my-java-app/
├── pom.xml                              # Java 21, Spring Boot 3.4.4
├── AGENTS.md                            # this file
├── .gitignore                           # target/, .idea/, *.iml, *.swp
├── src/main/java/com/example/
│   ├── Application.java                 # @SpringBootApplication
│   └── HelloController.java             # GET /hello → "Hello World v2"
├── src/main/resources/
│   └── application.yml                  # server.port=8080, actuator /health
├── docker/
│   └── Dockerfile                       # multi-stage (maven build → jre runtime)
├── local/
│   ├── build.sh                         # mvn clean package
│   ├── run.sh                           # mvn spring-boot:run
│   ├── docker.sh                        # docker build + run
│   ├── helm-validate.sh                 # helm lint + template
│   ├── k8s-deploy.sh                    # build → docker → kind load → helm install
│   ├── k8s-test.sh                      # port-forward + curl /hello + /health
│   ├── k8s-clean.sh                     # helm uninstall
│   ├── publish-image.sh                 # docker build + tag + push to GHCR
│   ├── publish-chart.sh                 # helm package + push to GHCR OCI
│   └── publish-all.sh                   # build → publish-image → publish-chart
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── .helmignore
│   └── templates/
│       ├── _helpers.tpl
│       ├── deployment.yaml              # liveness+readiness via /actuator/health
│       └── service.yaml                 # ClusterIP port 8080
└── .github/
    └── workflows/
        └── ci.yml                       # GHA: Maven build, Docker build (GHA cache), Helm lint
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

# Helm lint + validate
./local/helm-validate.sh

# Kind cluster lifecycle (generic scripts in ~/workflows/kubernetes/kind/)
../kind/kind-create.sh                   # create cluster (idempotent)
../kind/kind-start.sh                    # start after reboot
../kind/kind-stop.sh                     # stop cluster
../kind/kind-delete.sh                   # delete cluster
../kind/kind-status.sh                   # show cluster info
../kind/kind-load-image.sh my-java-app:latest  # load docker image

# GitOps publish (manual, while CI is not pushing)
./local/publish-all.sh [app-version] [chart-version]
# Defaults: app-version=1.1.0, chart-version=0.2.0
# If no version is given, bump the patch version automatically.
./local/k8s-deploy.sh                  # build → docker → kind load → helm install
./local/k8s-test.sh                    # port-forward + curl /hello + /health
./local/k8s-clean.sh                   # helm uninstall
```

## Docker Build Cache

The Dockerfile uses BuildKit `--mount=type=cache,target=/root/.m2` to persist the Maven repository across builds. The cache is stored internally by BuildKit (not a Docker volume). It is **shared across all projects** on the same machine that use the same cache target path. To isolate per project, an `id` parameter can be added:

```
--mount=type=cache,id=maven-<project>,target=/root/.m2
```

On CI (GitHub Actions), the Docker job uses `docker/build-push-action` with `type=gha` cache backend, which persists both Docker layers and the BuildKit Maven cache across workflow runs.

## Endpoints

- `GET /hello` → `"Hello World v2"`
- `GET /actuator/health` → health check (liveness/readiness probes)

## Design Decisions

- **Actuator** included specifically for Kubernetes health probes (`/actuator/health`)
- **No Ingress** — only ClusterIP Service (tested via `port-forward` or `minikube service`)
- **No HPA** — not needed for local testing
- **IntelliJ IDEA** — `.idea/` and `*.iml` in `.gitignore`
- **`<finalName>`** uses `${project.artifactId}` (not the deprecated `${artifactId}`)

## Agent Behavior

- When the user asks for **discussion, evaluation, or review**, the agent must first discuss and only make changes after the user explicitly authorizes them.
- When running `./local/publish-all.sh` without a version, auto-increment the patch version from `helm/Chart.yaml` (e.g., `1.0.0` → `1.0.1`). The same version is used for both image tag and chart.