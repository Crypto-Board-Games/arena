# Arena

Online Omok (Gomoku) platform.

## Structure

- `server/`: .NET backend (SignalR, REST API)
- `client/`: Flutter Web client

## Prerequisites

- .NET SDK (the repo currently targets `net10.0` in this environment)
- Flutter (stable)
- PostgreSQL (for real runs; tests use in-memory)

## Server

### Run

```bash
cd server/Arena.Server
dotnet run --urls http://localhost:5000
```

### Health

```bash
curl -s http://localhost:5000/health
```

## Client

### Run (Web)

```bash
cd client
flutter run -d chrome
```

### Build

```bash
cd client
flutter build web --release
```

## Auth

Endpoint: `POST /api/auth/google`

Development bypass (server Development environment only):

```json
{ "idToken": "dev_bypass_token", "email": "test@gmail.com", "displayName": "Test User" }
```
