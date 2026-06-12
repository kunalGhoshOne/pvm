# ── Stage 1: build ────────────────────────────────────────────────────────────
FROM golang:1.21-alpine AS builder

WORKDIR /src

COPY go.mod ./
COPY . .
RUN go mod tidy

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /out/pvm .

# ── Stage 2: export just the binary ───────────────────────────────────────────
FROM scratch AS export
COPY --from=builder /out/pvm /pvm
