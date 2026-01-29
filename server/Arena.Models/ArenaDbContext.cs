using Arena.Models.Entities;

using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Arena.Models;

public class ArenaDbContext(DbContextOptions options) : IdentityDbContext<ArenaUser>(options)
{
    public DbSet<Game> Games { get; set; }

    public DbSet<MatchQueue> MatchQueues { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<MatchQueue>()
            .HasIndex(m => m.UserId)
            .IsUnique();

        modelBuilder.Entity<Game>()
            .HasOne<ArenaUser>()
            .WithMany()
            .HasForeignKey(g => g.BlackPlayerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Game>()
            .HasOne<ArenaUser>()
            .WithMany()
            .HasForeignKey(g => g.WhitePlayerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Game>()
            .HasOne<ArenaUser>()
            .WithMany()
            .HasForeignKey(g => g.WinnerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<MatchQueue>()
            .HasOne<ArenaUser>()
            .WithMany()
            .HasForeignKey(m => m.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        base.OnModelCreating(modelBuilder);
    }
}