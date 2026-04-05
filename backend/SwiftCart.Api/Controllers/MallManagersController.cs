using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Models.Managers;
using SwiftCart.Api.Services;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/malls/{mallId}/managers")]
[Authorize(Roles = "admin,super_admin")]
public sealed class MallManagersController(
    SwiftCartDbContext dbContext,
    PasswordHashService passwordHashService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<MallManagerDto>>> GetAll(string mallId)
    {
        var normalizedMallId = Normalize(mallId);
        var managers = await dbContext.MallManagers
            .AsNoTracking()
            .Where(x => x.MallId == normalizedMallId)
            .OrderBy(x => x.ManagerId)
            .ToListAsync();

        return Ok(managers.Select(MallManagerDto.FromEntity).ToList());
    }

    [HttpGet("count")]
    public async Task<ActionResult<object>> GetCount(string mallId)
    {
        var normalizedMallId = Normalize(mallId);
        var count = await dbContext.MallManagers.CountAsync(x => x.MallId == normalizedMallId);
        return Ok(new { count });
    }

    [HttpPost]
    public async Task<ActionResult<MallManagerDto>> Create(
        string mallId,
        CreateMallManagerRequest request)
    {
        var normalizedMallId = Normalize(mallId);
        var normalizedManagerId = Normalize(request.ManagerId);
        var password = request.Password.Trim();

        if (normalizedMallId != Normalize(request.MallId))
        {
            return BadRequest(new { message = "Mall ID mismatch." });
        }

        if (string.IsNullOrWhiteSpace(normalizedManagerId) || string.IsNullOrWhiteSpace(password))
        {
            return BadRequest(new { message = "Manager ID and password are required." });
        }

        if (password.Length < 6)
        {
            return BadRequest(new { message = "Password must be at least 6 characters." });
        }

        var mallExists = await dbContext.Malls.AnyAsync(x => x.MallId == normalizedMallId);
        if (!mallExists)
        {
            return NotFound(new { message = "Mall not found." });
        }

        var existingManager = await dbContext.MallManagers
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.ManagerId == normalizedManagerId);
        if (existingManager is not null)
        {
            var message = existingManager.MallId == normalizedMallId
                ? "Manager ID already exists."
                : $"Manager ID already exists in mall {existingManager.MallId}.";
            return Conflict(new { message });
        }

        var now = DateTime.UtcNow;
        var entity = new MallManagerEntity
        {
            MallId = normalizedMallId,
            ManagerId = normalizedManagerId,
            AssignedUid = null,
            AssignedEmail = null,
            IsActive = true,
            PasswordHash = passwordHashService.ComputeSha256(password),
            PasswordUpdatedAt = now,
            CreatedAt = now,
            UpdatedAt = now,
        };

        dbContext.MallManagers.Add(entity);
        await dbContext.SaveChangesAsync();

        return CreatedAtAction(
            nameof(GetAll),
            new { mallId = normalizedMallId },
            MallManagerDto.FromEntity(entity));
    }

    [HttpPost("{managerId}/reset-password")]
    public async Task<IActionResult> ResetPassword(
        string mallId,
        string managerId,
        ResetMallManagerPasswordRequest request)
    {
        var entity = await FindManager(mallId, managerId);
        if (entity is null)
        {
            return NotFound(new { message = "Manager not found." });
        }

        var password = request.NewPassword.Trim();
        if (password.Length < 6)
        {
            return BadRequest(new { message = "Password must be at least 6 characters." });
        }

        entity.PasswordHash = passwordHashService.ComputeSha256(password);
        entity.PasswordUpdatedAt = DateTime.UtcNow;
        entity.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("{managerId}/unlink")]
    public async Task<IActionResult> Unlink(string mallId, string managerId)
    {
        var entity = await FindManager(mallId, managerId);
        if (entity is null)
        {
            return NotFound(new { message = "Manager not found." });
        }

        entity.AssignedUid = null;
        entity.AssignedEmail = null;
        entity.LinkedAt = null;
        entity.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("{managerId}/active")]
    public async Task<IActionResult> SetActive(
        string mallId,
        string managerId,
        SetMallManagerActiveRequest request)
    {
        var entity = await FindManager(mallId, managerId);
        if (entity is null)
        {
            return NotFound(new { message = "Manager not found." });
        }

        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    private async Task<MallManagerEntity?> FindManager(string mallId, string managerId)
    {
        var normalizedMallId = Normalize(mallId);
        var normalizedManagerId = Normalize(managerId);
        return await dbContext.MallManagers.FirstOrDefaultAsync(
            x => x.MallId == normalizedMallId && x.ManagerId == normalizedManagerId);
    }

    private static string Normalize(string value) => value.Trim().ToUpperInvariant();
}
