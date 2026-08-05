# my-java-app

## Tech Stack

- **Java 21** — language version
- **Spring Boot 3.4.4** with `spring-boot-starter-web` + `spring-boot-starter-actuator`
- **Maven** — build tool
- **Docker** — multi-stage build with BuildKit cache mounts
- **Helm v2** — Kubernetes packaging (Deployment + Service ClusterIP + Ingress, no HPA)
- **GitHub Actions** — CI pipeline: Maven build, Docker build (with GHA cache), Helm lint + **publish automático** no push para `main` (imagem + chart no GHCR, versão `1.0.<run_number>`)

## Project Structure

```
my-java-app/
├── pom.xml                              # Java 21, Spring Boot 3.4.4
├── AGENTS.md                            # this file
├── .gitignore                           # target/, .idea/, *.iml, *.swp
├── src/main/java/com/example/
│   ├── Application.java                 # @SpringBootApplication
│   └── HelloController.java             # GET /hello → "Hello World v5"
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
│       ├── ingress.yaml                 # Ingress (nginx, controlado por values.ingress.enabled)
│       └── service.yaml                 # ClusterIP port 8080
└── .github/
    └── workflows/
        └── ci.yml                       # GHA: Maven build, Docker build (GHA cache), Helm lint, publish (main)
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

# GitOps publish (100% automático via CI no push para main)
# CI publica imagem+chart com versão 1.0.<run_number> E faz bump+commit do
# tag em apps/my-java-app/helm-release.yaml no gitops-config (Flux deploys).
# Scripts locais (publish-all.sh) continuam disponíveis para uso manual.
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

- `GET /hello` → `"Hello World v5"`
- `GET /actuator/health` → health check (liveness/readiness probes)

## Design Decisions

- **Actuator** included specifically for Kubernetes health probes (`/actuator/health`)
- **Ingress** — suportado via template condicional (`ingress.enabled`), usa nginx por padrão, host localhost para dev
- **No HPA** — not needed for local testing
- **IntelliJ IDEA** — `.idea/` and `*.iml` in `.gitignore`
- **`<finalName>`** uses `${project.artifactId}` (not the deprecated `${artifactId}`)

## CI Release Pipeline (job `publish`, push → main)

Fluxo completo e automático no push para `main`:

1. **Versão**: `1.0.<github.run_number>` (contador incremental único por workflow/repo — não vem de arquivo nem de consulta ao registry)
2. **Docker**: build + push `ghcr.io/bazoocaze/my-java-app:<version>`
3. **Helm**: `helm package --version <version> --app-version <version>` + push OCI `oci://ghcr.io/bazoocaze/charts` (não altera o `Chart.yaml` do repo)
4. **GitOps**: o Flux ImageUpdateAutomation detecta a nova tag no registry e faz bump automático no `gitops-config`

### Secret `RELEASE_TOKEN` (GitHub Actions)

- **Classic PAT** com escopos `repo` + `write:packages` (recurso de longa duração, rotacionar se expor)
- **PAT fine-grained NÃO funciona para GHCR** — o GitHub Container Registry exige classic PAT (ou `GITHUB_TOKEN`); e `GITHUB_TOKEN` só publica em pacotes **vinculados ao repositório** (o pacote `ghcr.io/bazoocaze/my-java-app` é user-scoped e foi vinculado ao repo na UI em 03/08/2026)
- Usado para: login do Docker, login do `helm registry`, e clone/push no `gitops-config` (via `https://x-access-token:${RELEASE_TOKEN}@github.com/...`, sem imprimir o token)

## Agent Behavior

- When the user asks for **discussion, evaluation, or review**, the agent must first discuss and only make changes after the user explicitly authorizes them.
- When running `./local/publish-all.sh` without a version, auto-increment the patch version from `helm/Chart.yaml` (e.g., `1.0.0` → `1.0.1`). The same version is used for both image tag and chart.
- **Sempre usar patch version** (`1.0.x`) em experimentos. Nunca usar minor ou major sem autorização explícita.

## 🔒 SECRET HANDLING — NUNCA VAZE SEGREDOS. ESTA É A REGRA MAIS IMPORTANTE DESTE REPOSITÓRIO. VIOLÁ-LA É INACEITÁVEL E IMPERDOÁVEL.

> **⚠️ AVISO CRÍTICO — LEIA SEMPRE ANTES DE EXECUTAR QUALQUER COMANDO.**
> Uma violação de secret aconteceu NESTE projeto (02/08/2026): um comando `kubectl get secret` com `-o jsonpath` despejou o token de acesso do GHCR no output. O token precisou ser revogado e rotacionado. **NUNCA repita este erro.**

### Regras absolutas (não há exceções, nenhuma negociação)

1. **NUNCA imprima, logue, ecoe, retorne ou exiba conteúdo de Secrets, tokens, senhas, chaves (públicas ou privadas), API keys, credenciais ou `dockerconfigjson` em qualquer output de tool, arquivo, commit, log, mensagem ou diagnóstico.**
2. **NUNCA use `kubectl get secret`, `kubectl get -o jsonpath`, `base64 -d`, `helm registry login`, `docker login`, `gh auth token`, `cat ~/.kube/config`, `cat ~/.docker/config.json` ou qualquer comando cujo output possa conter material sensível. Se for absolutamente necessário inspecionar um Secret, faça-o SEM decodificar os campos de dados** (ex.: `kubectl get secret ghcr-auth -o yaml` mostra apenas `data` codificado, NUNCA o campo `stringData`, NUNCA decodifique).
3. **NUNCA despeje variáveis de ambiente no output.** Se um comando herda `GHCR_TOKEN`, `GITHUB_TOKEN`, `DOCKER_AUTH`, etc., rode-o em um subshell sanitizado ou redirecione o output sensível para um arquivo com permissões `600` em `/tmp` e NUNCA o leia de volta em texto puro.
4. **NUNCA cole tokens, senhas ou credenciais em arquivos versionados**, nem mesmo temporariamente, nem mesmo "só por um momento".
5. **Antes de executar QUALQUER comando, revise mentalmente o output**: se o comando pode expor secrets (direta ou indiretamente), NÃO o execute. Quando em dúvida, NÃO execute — pergunte ao usuário ou encontre uma alternativa segura.
6. **NUNCA escreva o valor de um token/secret em uma mensagem para o usuário, em um resumo, em um diff, em um PR ou em um commit message.** Referencie-o apenas pelo nome do recurso (ex.: "o secret `ghcr-auth`").

### Checklist obrigatório antes de rodar comandos de inspeção no cluster

- O comando decodifica algo? → **NÃO RODE**.
- O comando tem `-o jsonpath`, `-o go-template`, `-o yaml` sobre Secret? → **NÃO RODE** (ou use apenas campos estruturais, nunca `data`/`stringData`).
- O output pode conter um token regex-like (`gho_`, `ghp_`, `ghs_`, `ghu_`, `AKIA`, `BEGIN ... PRIVATE KEY`, etc.)? → **NÃO RODE**.
- Se precisar verificar autenticação/credenciais, use comandos que NÃO retornam o segredo (ex.: `docker login` em modo interativo, `gh auth status`, `flux get sources`).

### Se, apesar de tudo, um secret for exposto

1. **AVISE O USUÁRIO IMEDIATAMENTE** e com clareza.
2. **NÃO continue o trabalho** até o usuário revogar/rotacionar a credencial.
3. **NUNCA tente "consertar" silenciosamente** reescrevendo o histórico ou o log — o segredo já foi comprometido e precisa ser rotacionado pelo usuário.
4. Depois de rotacionado, registre o incidente aqui (seção acima) para que o próximo agente aprenda.