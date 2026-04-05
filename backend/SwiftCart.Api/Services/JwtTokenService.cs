using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using SwiftCart.Api.Configuration;
using SwiftCart.Api.Models.Auth;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Models.Managers;
using SwiftCart.Api.Models.Malls;

namespace SwiftCart.Api.Services;

public sealed class JwtTokenService(IOptions<JwtOptions> options)
{
    private readonly JwtOptions _options = options.Value;

    public AuthResponse CreateAdminToken(AdminEntity admin)
    {
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_options.ExpiryMinutes);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, admin.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, admin.Email),
            new(ClaimTypes.Name, admin.Name),
            new(ClaimTypes.Role, admin.Role),
        };

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_options.SecretKey));
        var credentials = new SigningCredentials(
            key,
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: expiresAtUtc,
            signingCredentials: credentials);

        return new AuthResponse
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            ExpiresAtUtc = expiresAtUtc,
            User = new AdminUserDto
            {
                AdminId = admin.Id.ToString(),
                Name = admin.Name,
                Email = admin.Email,
                Role = admin.Role,
                CreatedAt = admin.CreatedAt,
            },
        };
    }

    public MallManagerAuthResponse CreateMallManagerToken(
        MallManagerEntity manager,
        MallEntity mall)
    {
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_options.ExpiryMinutes);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, manager.ManagerId),
            new(JwtRegisteredClaimNames.Email, manager.AssignedEmail ?? string.Empty),
            new(ClaimTypes.Name, manager.ManagerId),
            new(ClaimTypes.Role, "manager"),
            new("mall_id", manager.MallId),
            new("manager_id", manager.ManagerId),
        };

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_options.SecretKey));
        var credentials = new SigningCredentials(
            key,
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: expiresAtUtc,
            signingCredentials: credentials);

        return new MallManagerAuthResponse
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            ExpiresAtUtc = expiresAtUtc,
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
    }

    public UserAuthResponse CreateCustomerUserToken(UserProfileEntity user)
    {
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_options.ExpiryMinutes);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Uid),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(ClaimTypes.Name, user.DisplayName),
            new(ClaimTypes.Role, "customer"),
            new("user_id", user.Uid),
        };

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_options.SecretKey));
        var credentials = new SigningCredentials(
            key,
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: expiresAtUtc,
            signingCredentials: credentials);

        return new UserAuthResponse
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            ExpiresAtUtc = expiresAtUtc,
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
    }
}
