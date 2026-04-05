using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Auth;
using SwiftCart.Api.Services;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController(
    SwiftCartDbContext dbContext,
    PasswordHashService passwordHashService,
    JwtTokenService jwtTokenService) : ControllerBase
{
    [HttpPost("admin/login")]
    public async Task<IActionResult> AdminLogin(AdminLoginRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var password = request.Password.Trim();

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            return BadRequest(new { message = "Email and password are required." });
        }

        var admin = await dbContext.Admins
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Email == email);

        if (admin is null || !admin.IsActive)
        {
            return Unauthorized(new { message = "Invalid credentials." });
        }

        var hashedPassword = passwordHashService.ComputeSha256(password);
        if (!string.Equals(admin.PasswordHash, hashedPassword, StringComparison.Ordinal))
        {
            return Unauthorized(new { message = "Invalid credentials." });
        }

        var response = jwtTokenService.CreateAdminToken(admin);
        return Ok(response);
    }
}
