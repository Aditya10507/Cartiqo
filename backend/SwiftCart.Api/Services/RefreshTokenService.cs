using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SwiftCart.Api.Configuration;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Auth;

namespace SwiftCart.Api.Services;

public sealed class RefreshTokenService(
    SwiftCartDbContext dbContext,
    JwtTokenService jwtTokenService,
    IOptions<RefreshTokenOptions> options)
{
    private readonly RefreshTokenOptions _options = options.Value;

    public async Task SaveRefreshTokenAsync(RefreshToken refreshToken)
    {
        // Revoke old tokens if MaxActiveTokens is exceeded
        var existingTokens = await dbContext.RefreshTokens
            .Where(x => x.UserId == refreshToken.UserId && x.IsActive)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        if (existingTokens.Count >= _options.MaxActiveTokens)
        {
            foreach (var oldToken in existingTokens.Skip(_options.MaxActiveTokens - 1))
            {
                oldToken.IsRevoked = true;
            }
        }

        dbContext.RefreshTokens.Add(refreshToken);
        await dbContext.SaveChangesAsync();
    }

    public async Task RevokeRefreshTokenAsync(string token)
    {
        var refreshToken = await dbContext.RefreshTokens.SingleOrDefaultAsync(x => x.Token == token);
        if (refreshToken is not null)
        {
            refreshToken.IsRevoked = true;
            await dbContext.SaveChangesAsync();
        }
    }
}
