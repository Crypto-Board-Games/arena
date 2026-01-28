## PostgreSQL Not Available (2026-01-28)

### Issue
- PostgreSQL not installed on system
- Docker not available
- Cannot apply migration without database running
- Requires sudo access to install PostgreSQL

### Workaround
- Migration files created and verified correct
- All tests passing (11 entity tests + 1 existing)
- Database update command documented for when PostgreSQL is available

### Resolution Required
User needs to:
1. Install PostgreSQL: `sudo apt-get install postgresql postgresql-contrib`
2. Start service: `sudo systemctl start postgresql`
3. Create database: `sudo -u postgres createdb arena`
4. Apply migration: `cd server && dotnet ef database update --project Arena.Models --startup-project Arena.Server`

### Alternative: Docker
```bash
docker run --name arena-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=arena -p 5432:5432 -d postgres:16
```
