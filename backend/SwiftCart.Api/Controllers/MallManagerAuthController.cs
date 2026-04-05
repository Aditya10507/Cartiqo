using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Managers;
using SwiftCart.Api.Services;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/auth/mall-manager")]
public sealed class MallManagerAuthController(
    SwiftCartDbContext dbContext,
    PasswordHashService passwordHashService,
    JwtTokenService jwtTokenService) : ControllerBase
{
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<MallManagerAuthResponse>> Login(MallManagerLoginRequest request)
    {
        var normalizedManagerId = request.ManagerId.Trim().ToUpperInvariant();
        var password = request.Password.Trim();

        if (string.IsNullOrWhiteSpace(normalizedManagerId) || string.IsNullOrWhiteSpace(password))
        {
            return BadRequest(new { message = "Manager ID and password are required." });
        }

        var manager = await dbContext.MallManagers.FirstOrDefaultAsync(
            x => x.ManagerId == normalizedManagerId);
        if (manager is null)
        {
            return NotFound(new { message = "Manager account not found. Ask admin to reset the password." });
        }

        if (!manager.IsActive)
        {
            return BadRequest(new { message = "Manager account is disabled." });
        }

        if (string.IsNullOrWhiteSpace(manager.PasswordHash))
        {
            return BadRequest(new { message = "Manager password is not set. Ask admin to reset it." });
        }

        if (passwordHashService.ComputeSha256(password) != manager.PasswordHash)
        {
            return Unauthorized(new { message = "Invalid manager ID or password." });
        }

        var mall = await dbContext.Malls.FirstOrDefaultAsync(x => x.MallId == manager.MallId);
        if (mall is null)
        {
            return NotFound(new { message = "Mall not found for this manager." });
        }

        manager.LastLoginAt = DateTime.UtcNow;
        manager.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return Ok(jwtTokenService.CreateMallManagerToken(manager, mall));
    }
}
