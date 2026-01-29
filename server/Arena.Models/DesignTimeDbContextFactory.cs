using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Arena.Models;

public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<ArenaDbContext>
{
    public ArenaDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<ArenaDbContext>();
        optionsBuilder.UseNpgsql("Host=localhost;Database=arena;Username=postgres;Password=postgres");
        return new ArenaDbContext(optionsBuilder.Options);
    }
}
