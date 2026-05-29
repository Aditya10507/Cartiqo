using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Auth;
using SwiftCart.Api.Models.Managers;
using SwiftCart.Api.Models.Public;
using SwiftCart.Api.Models.Users;
using SwiftCart.Api.Services;

namespace SwiftCart.Api.Controllers;

public static class AuthenticationController
{
    public static IEndpointRouteBuilder MapAuthenticationEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth");

        group.MapPost("/admin/login", AdminLogin);
        group.MapPost("/manager/login", MallManagerLogin);
        group.MapPost("/user/login", UserLogin);
        group.MapPost("/refresh", RefreshToken);

        return app;
    }

    public static async Task<Results<Ok<AuthResponse>, BadRequest<string>>> AdminLogin(
        AdminLoginRequest request,
        SwiftCartDbContext dbContext,
        PasswordHashService passwordHashService,
        JwtTokenService jwtTokenService,
        RefreshTokenService refreshTokenService,
        IValidator<AdminLoginRequest> validator)
    {
        var validationResult = await validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            return TypedResults.BadRequest(validationResult.ToString());
        }

        if (!string.Equals(request.Email, "Admin@swiftcart.com", StringComparison.OrdinalIgnoreCase) || 
            request.Password != "admin123")
        {
            return TypedResults.BadRequest("Invalid email or password.");
        }

        var admin = await dbContext.Admins.SingleOrDefaultAsync(
            x => x.Email == request.Email);

        if (admin is null)
        {
            return TypedResults.BadRequest("Invalid email or password.");
        }

        var (response, token) = jwtTokenService.CreateAdminToken(admin);
        await refreshTokenService.SaveRefreshTokenAsync(token);

        return TypedResults.Ok(response);
    }

    public static async Task<Results<Ok<MallManagerAuthResponse>, BadRequest<string>>> MallManagerLogin(
        MallManagerLoginRequest request,
        SwiftCartDbContext dbContext,
        PasswordHashService passwordHashService,
        JwtTokenService jwtTokenService,
        RefreshTokenService refreshTokenService,
        IValidator<MallManagerLoginRequest> validator)
    {
        var validationResult = await validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            return TypedResults.BadRequest(validationResult.ToString());
        }

        if (!string.Equals(request.Email, "Manager@swiftcart.com", StringComparison.OrdinalIgnoreCase) || 
            request.Password != "manager123")
        {
            return TypedResults.BadRequest("Invalid email or password.");
        }

        var manager = await dbContext.MallManagers.SingleOrDefaultAsync(
            x => x.AssignedEmail == request.Email);

        if (manager is null)
        {
            return TypedResults.BadRequest("Invalid email or password.");
        }

        var mall = await dbContext.Malls.SingleOrDefaultAsync(
            x => x.MallId == manager.MallId);

        if (mall is null)
        {
            return TypedResults.BadRequest("Mall not found.");
        }

        var (response, token) = jwtTokenService.CreateMallManagerToken(manager, mall);
        await refreshTokenService.SaveRefreshTokenAsync(token);

        return TypedResults.Ok(response);
    }

    public static async Task<Results<Ok<UserAuthResponse>, BadRequest<string>>> UserLogin(
        UserLoginRequest request,
        SwiftCartDbContext dbContext,
        PasswordHashService passwordHashService,
        JwtTokenService jwtTokenService,
        RefreshTokenService refreshTokenService,
        IValidator<UserLoginRequest> validator)
    {
        var validationResult = await validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            return TypedResults.BadRequest(validationResult.ToString());
        }

        if (!string.Equals(request.Email, "User@swiftcart.com", StringComparison.OrdinalIgnoreCase) || 
            request.Password != "user123")
        {
            return TypedResults.BadRequest("Invalid email or password.");
        }

        var user = await dbContext.UserProfiles.SingleOrDefaultAsync(
            x => x.Email == request.Email);

        if (user is null)
        {
            return TypedResults.BadRequest("Invalid email or password.");
        }

        var (response, token) = jwtTokenService.CreateUserToken(user);
        await refreshTokenService.SaveRefreshTokenAsync(token);

        return TypedResults.Ok(response);
    }

    public static async Task<Results<Ok<AuthRefreshResponse>, BadRequest<string>>> RefreshToken(
        RefreshTokenRequest request,
        SwiftCartDbContext dbContext,
        JwtTokenService jwtTokenService,
        RefreshTokenService refreshTokenService,
        IValidator<RefreshTokenRequest> validator)
    {
        var validationResult = await validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            return TypedResults.BadRequest(validationResult.ToString());
        }

        var now = DateTime.UtcNow;
        var storedRefreshToken = await dbContext.RefreshTokens.SingleOrDefaultAsync(
            x => x.Token == request.RefreshToken && 
                 !x.IsRevoked && 
                 x.ExpiresAt > now);

        if (storedRefreshToken is null)
        {
            return TypedResults.BadRequest("Invalid or expired refresh token.");
        }

        await refreshTokenService.RevokeRefreshTokenAsync(storedRefreshToken.Token);

        var userId = storedRefreshToken.UserId;

        var userProfile = await dbContext.UserProfiles.SingleOrDefaultAsync(x => x.Uid == userId);
        if (userProfile is not null)
        {
            var (response, token) = jwtTokenService.CreateUserToken(userProfile);
            await refreshTokenService.SaveRefreshTokenAsync(token);
            return TypedResults.Ok(new AuthRefreshResponse
            {
                Token = response.Token,
                RefreshToken = response.RefreshToken,
                ExpiresAtUtc = response.ExpiresAtUtc,
            });
        }

        if (Guid.TryParse(userId, out var adminGuid))
        {
            var admin = await dbContext.Admins.SingleOrDefaultAsync(x => x.Id == adminGuid);
            if (admin is not null)
            {
                var (response, token) = jwtTokenService.CreateAdminToken(admin);
                await refreshTokenService.SaveRefreshTokenAsync(token);
                return TypedResults.Ok(new AuthRefreshResponse
                {
                    Token = response.Token,
                    RefreshToken = response.RefreshToken,
                    ExpiresAtUtc = response.ExpiresAtUtc,
                });
            }
        }

        var mallManager = await dbContext.MallManagers.SingleOrDefaultAsync(x => x.ManagerId == userId);
        if (mallManager is not null)
        {
            var mall = await dbContext.Malls.SingleOrDefaultAsync(x => x.MallId == mallManager.MallId);
            if (mall is null)
            {
                return TypedResults.BadRequest("Mall not found for manager.");
            }
            var (response, token) = jwtTokenService.CreateMallManagerToken(mallManager, mall);
            await refreshTokenService.SaveRefreshTokenAsync(token);
            return TypedResults.Ok(new AuthRefreshResponse
            {
                Token = response.Token,
                RefreshToken = response.RefreshToken,
                ExpiresAtUtc = response.ExpiresAtUtc,
            });
        }

        return TypedResults.BadRequest("User not found for refresh token.");
    }
}
