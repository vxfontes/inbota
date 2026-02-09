FROM golang:1.25-alpine AS build

WORKDIR /app

COPY go.mod ./

RUN go mod download

COPY . ./

RUN go build -o /bin/api ./cmd/api

FROM alpine:3.20

RUN adduser -D -g '' app
USER app

COPY --from=build /bin/api /bin/api

EXPOSE 8080

CMD ["/bin/api"]
