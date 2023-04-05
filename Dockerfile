FROM golang:1.19-alpine AS builder
ENV CGO_ENABLED=0
WORKDIR /backend
COPY backend/go.* .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download
COPY backend/. .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -ldflags="-s -w" -o bin/service

FROM --platform=$BUILDPLATFORM node:18.12-alpine3.16 AS client-builder
WORKDIR /ui
# cache packages in layer
COPY ui/package.json /ui/package.json
COPY ui/package-lock.json /ui/package-lock.json
RUN --mount=type=cache,target=/usr/src/app/.npm \
    npm set cache /usr/src/app/.npm && \
    npm ci
# install
COPY ui /ui
RUN npm run build

FROM alpine
LABEL org.opencontainers.image.title="Mindsdb" \
    org.opencontainers.image.description="Mindsdb Docker Extension" \
    org.opencontainers.image.vendor="Ajeet Singh Raina" \
    com.docker.desktop.extension.api.version="0.3.0" \
    com.docker.extension.screenshots="" \
    com.docker.extension.categories="Databases" \
    com.docker.desktop.extension.icon="https://uploads-ssl.webflow.com/62a8755be8bcc86e6307def8/63b75a4a90fefbed813c6549_Mindsdb-V%20logo.svg" \
    com.docker.extension.detailed-description="Mindsdb is an open-source machine learning framework that allows users to create predictive models using natural language queries. Mindsdb uses a combination of automated machine learning (AutoML) techniques and a knowledge graph to analyze data and generate predictions." \
    com.docker.extension.publisher-url="https://github.com/collabnix/mindsdb-docker-extension" \
    com.docker.extension.additional-urls='[{"title":"Documentation","url":"https://docs.mindsdb.com/what-is-mindsdb/"}, {"title":"Support","url":"https://github.com/mindsdb/mindsdb/discussions"}, {"title":"Terms of Service","url":"https://mindsdb.com/terms"}, {"title":"Privacy policy","url":"https://mindsdb.com/privacy-policy/"}]' \
    com.docker.extension.changelog="https://raw.githubusercontent.com/collabnix/mindsdb-docker-extension/main/CHANGELOG.md"

COPY --from=builder /backend/bin/service /
COPY docker-compose.yaml .
COPY metadata.json .
COPY mindsdb.svg .
COPY --from=client-builder /ui/build ui
CMD /service -socket /run/guest-services/backend.sock
