# ---------- 阶段 1：构建 Vue 前端 ----------
FROM node:20-alpine AS web-builder
WORKDIR /build
COPY web/package.json web/package-lock.json* ./
RUN npm install
COPY web/ ./
RUN npm run build

# ---------- 阶段 2：编译 Go 后端 ----------
FROM golang:1.22-alpine AS go-builder
WORKDIR /build
COPY server/go.mod server/go.sum* ./
RUN go mod download || true
COPY server/ ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o badminton-server .

# ---------- 阶段 3：运行镜像 ----------
FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata && \
    adduser -D -u 10001 appuser
ENV TZ=Asia/Shanghai \
    ADDR=:8080 \
    DATA_DIR=/data \
    WEB_DIR=/app/web
WORKDIR /app
COPY --from=go-builder /build/badminton-server /app/badminton-server
COPY --from=web-builder /build/dist /app/web
VOLUME ["/data"]
EXPOSE 8080
USER appuser
ENTRYPOINT ["/app/badminton-server"]
