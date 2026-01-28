using Microsoft.EntityFrameworkCore;
using Arena.Models.Entities;

namespace Arena.Models;

public class ArenaDbContext : DbContext
{
    public ArenaDbContext(DbContextOptions<ArenaDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Game> Games { get; set; }
    public DbSet<MatchQueue> MatchQueues { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>()
            .HasIndex(u => u.GoogleId)
            .IsUnique();
        
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        modelBuilder.Entity<MatchQueue>()
            .HasIndex(m => m.UserId)
            .IsUnique();

        modelBuilder.Entity<Game>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(g => g.BlackPlayerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Game>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(g => g.WhitePlayerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Game>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(g => g.WinnerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<MatchQueue>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(m => m.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
