# hello-service

A small Go HTTP service.

| Endpoint | Returns |
|---|---|
| `GET /healthz` | `ok` while the process is up |
| `GET /info` | JSON with the service name and the value of `APP_ENV` |

It listens on `PORT` (default `8080`).

```sh
go test ./...
go run .
curl localhost:8080/info
```

## The task

Deploy this service to a **staging** and a **production** environment, with CI/CD.

- A change merged to `main` should reach staging without anyone running commands by hand.
- Production deploys need a human approval.

You have 60 minutes. Use any tools you like, including AI. Please talk us through what you're doing as you go, and ask us anything.
