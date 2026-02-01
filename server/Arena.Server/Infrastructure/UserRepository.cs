using Arena.Models;
using Arena.Models.Entities;

using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Infrastructure;

public class UserRepository(ArenaDbContext dbContext)
{
    public IEnumerable<(string userId, string loginProvider)> ConfirmedExistingUsers(string deviceId)
    {
        var users = from t in dbContext.UserTokens.AsNoTracking()
                    where nameof(DeviceIdentity.DeviceId).Equals(t.Name) && deviceId.Equals(t.Value)
                    select new
                    {
                        t.UserId,
                        t.LoginProvider
                    };

        foreach (var user in users.ToArray())
        {
            yield return (user.UserId, user.LoginProvider);
        }
    }
}