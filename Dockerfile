# syntax=docker/dockerfile:1

# Build stage: runs on the host's native platform and cross-compiles for the target.
# Build with: docker build --platform linux/amd64 -t hello-service .
FROM --platform=$BUILDPLATFORM golang:1.24 AS build
WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .
RUN go test ./...
ARG TARGETOS=linux TARGETARCH=amd64
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/hello-service .

# Runtime stage: distroless static, nonroot tag (uid/gid 65532).
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/hello-service /hello-service
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/hello-service"]
