using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using SwiftCart.Api.Configuration;
using SwiftCart.Api.Models.Auth;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Models.Managers;
using SwiftCart.Api.Models.Malls;

namespace SwiftCart.Api.Services;

public sealed class JwtTokenService(
    IOptions<JwtOptions> jwtOptions,
    IOptions<RefreshTokenOptions> refreshTokenOptions)
{
    private readonly JwtOptions _jwtOptions = jwtOptions.Value;
    private readonly RefreshTokenOptions _refreshTokenOptions = refreshTokenOptions.Value;

    public (AuthResponse Response, RefreshToken RefreshToken) CreateAdminToken(AdminEntity admin)
    {
        var (token, expiresAtUtc) = GenerateAccessToken(
            admin.Id.ToString(),
            admin.Email,
            admin.Name,
            admin.Role);

        var refreshToken = GenerateRefreshToken(admin.Id.ToString());

        var response = new AuthResponse
        {
            Token = token,
            ExpiresAtUtc = expiresAtUtc,
            RefreshToken = refreshToken.Token,
            User = new AdminUserDto
            {
                AdminId = admin.Id.ToString(),
                Name = admin.Name,
                Email = admin.Email,
                Role = admin.Role,
                CreatedAt = admin.CreatedAt,
            },
        };

        return (response, refreshToken);
    }

    public (MallManagerAuthResponse Response, RefreshToken RefreshToken) CreateMallManagerToken(
        MallManagerEntity manager,
        MallEntity mall)
    {
        var (token, expiresAtUtc) = GenerateAccessToken(
            manager.ManagerId,
            manager.AssignedEmail ?? string.Empty,
            manager.FullName,
            "manager",
            new Dictionary<string, string>
            {
                { "mall_id", manager.MallId },
                { "manager_id", manager.ManagerId },
            });

        var refreshToken = GenerateRefreshToken(manager.ManagerId);

        var response = new MallManagerAuthResponse
        {
            Token = token,
            ExpiresAtUtc = expiresAtUtc,
            RefreshToken = refreshToken.Token,
            Manager = new MallManagerSessionDto
            {
                MallId = manager.MallId,
                ManagerId = manager.ManagerId,
                Email = manager.AssignedEmail ?? string.Empty,
                FullName = manager.FullName,
                PhoneNumber = manager.PhoneNumber,
                DateOfJoining = manager.DateOfJoining,
                IsActive = manager.IsActive,
            },
            Mall = MallDto.FromEntity(mall),
        };

        return (response, refreshToken);
    }

    public (UserAuthResponse Response, RefreshToken RefreshToken) CreateUserToken(UserProfileEntity user)
    {
        var (token, expiresAtUtc) = GenerateAccessToken(
            user.Uid,
            user.Email,
            user.Username,
            "customer");

        var refreshToken = GenerateRefreshToken(user.Uid);

        var response = new UserAuthResponse
        {
            Token = token,
            ExpiresAtUtc = expiresAtUtc,
            RefreshToken = refreshToken.Token,
            User = new UserSessionDto
            {
                Uid = user.Uid,
                Username = user.Username,
                FullName = user.FullName,
                DisplayName = user.DisplayName,
                Email = user.Email,
                PhoneNumber = user.Phone,
                PhotoUrl = user.PhotoUrl,
                EmailVerified = user.EmailVerified,
                Provider = user.Provider,
            },
        };

        return (response, refreshToken);
    }

    private (string Token, DateTime ExpiresAtUtc) GenerateAccessToken(
        string subject,
        string email,
        string name,
        string role,
        Dictionary<string, string>? customClaims = null)
    {
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_jwtOptions.ExpiryMinutes);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, subject),
            new(JwtRegisteredClaimNames.Email, email),
            new(ClaimTypes.Name, name),
            new(ClaimTypes.Role, role),
        };

        if (customClaims is not null)
        {
            claims.AddRange(customClaims.Select(c => new Claim(c.Key, c.Value)));
        }

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_jwtOptions.SecretKey));
        var credentials = new SigningCredentials(
            key,
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _jwtOptions.Issuer,
            audience: _jwtOptions.Audience,
            claims: claims,
            expires: expiresAtUtc,
            signingCredentials: credentials);

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAtUtc);
    }

    public RefreshToken GenerateRefreshToken(string userId)
    {
        var randomNumber = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);

        return new RefreshToken
        {
            Token = Convert.ToBase64String(randomNumber),
            ExpiresAt = DateTime.UtcNow.AddMinutes(_refreshTokenOptions.ExpiryMinutes),
            CreatedAt = DateTime.UtcNow,
            UserId = userId,
        };
    }
}
