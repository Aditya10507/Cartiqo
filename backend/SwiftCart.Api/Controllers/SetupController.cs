using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SwiftCart.Api.Configuration;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Auth;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Services;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class SetupController(
    IWebHostEnvironment environment,
    IOptions<SetupOptions> setupOptions,
    SwiftCartDbContext dbContext,
    PasswordHashService passwordHashService) : ControllerBase
{
    [HttpPost("bootstrap-admin")]
    public async Task<IActionResult> BootstrapAdmin(BootstrapAdminRequest request)
    {
        var options = setupOptions.Value;
        if (!environment.IsDevelopment() || !options.EnableBootstrapEndpoints)
        {
            return NotFound();
        }

        if (!string.Equals(request.SetupKey, options.BootstrapKey, StringComparison.Ordinal))
        {
            return Unauthorized(new { message = "Invalid setup key." });
        }

        var hasAnyAdmin = await dbContext.Admins.AnyAsync();
        if (hasAnyAdmin)
        {
            return Conflict(new { message = "Bootstrap admin already exists." });
        }

        var email = request.Email.Trim().ToLowerInvariant();
        var password = request.Password.Trim();
        if (string.IsNullOrWhiteSpace(request.Name) ||
            string.IsNullOrWhiteSpace(email) ||
            string.IsNullOrWhiteSpace(password))
        {
            return BadRequest(new { message = "Name, email, and password are required." });
        }

        var admin = new AdminEntity
        {
            Name = request.Name.Trim(),
            Email = email,
            PasswordHash = passwordHashService.ComputeSha256(password),
            Role = string.IsNullOrWhiteSpace(request.Role) ? "super_admin" : request.Role.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.Admins.Add(admin);
        await dbContext.SaveChangesAsync();

        return Created(string.Empty, new
        {
            message = "Bootstrap admin created.",
            adminId = admin.Id,
            admin.Email,
            admin.Role,
        });
    }
}
