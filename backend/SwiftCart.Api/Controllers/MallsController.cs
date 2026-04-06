using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Malls;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class MallsController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet]
    [Authorize(Roles = "admin,super_admin")]
    public async Task<ActionResult<List<MallDto>>> GetAll()
    {
        var malls = await dbContext.Malls
            .AsNoTracking()
            .OrderBy(x => x.Name)
            .ToListAsync();

        return Ok(malls.Select(MallDto.FromEntity).ToList());
    }

    [HttpGet("{mallId}")]
    [Authorize(Roles = "admin,super_admin,manager")]
    public async Task<ActionResult<MallDto>> GetById(string mallId)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var mall = await dbContext.Malls
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.MallId == normalizedMallId);

        if (mall is null)
        {
            return NotFound(new { message = "Mall not found." });
        }

        return Ok(MallDto.FromEntity(mall));
    }

    [HttpPost]
    [Authorize(Roles = "admin,super_admin")]
    public async Task<ActionResult<MallDto>> Create(MallDto request)
    {
        var entity = request.ToEntity();

        if (string.IsNullOrWhiteSpace(entity.MallId) || string.IsNullOrWhiteSpace(entity.Name))
        {
            return BadRequest(new { message = "Mall ID and name are required." });
        }

        var exists = await dbContext.Malls.AnyAsync(x => x.MallId == entity.MallId);
        if (exists)
        {
            return Conflict(new { message = "Mall already exists." });
        }

        dbContext.Malls.Add(entity);
        await dbContext.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { mallId = entity.MallId }, MallDto.FromEntity(entity));
    }

    [HttpPut("{mallId}")]
    [Authorize(Roles = "admin,super_admin")]
    public async Task<ActionResult<MallDto>> Update(string mallId, MallDto request)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        var entity = await dbContext.Malls.FirstOrDefaultAsync(x => x.MallId == normalizedMallId);

        if (entity is null)
        {
            return NotFound(new { message = "Mall not found." });
        }

        entity.Name = request.Name.Trim();
        entity.OwnerName = request.OwnerName?.Trim();
        entity.OwnerEmail = request.OwnerEmail?.Trim();
        entity.City = request.City?.Trim();
        entity.State = request.State?.Trim();
        entity.SubscriptionStartDate = request.SubscriptionStartDate;
        entity.SubscriptionEndDate = request.SubscriptionEndDate;
        entity.PlanType = request.PlanType.Trim();
        entity.MaxProducts = request.MaxProducts;
        entity.IsActive = request.IsActive;
        entity.AreaCode = request.AreaCode?.Trim();
        entity.EstYear = request.EstYear;
        entity.MallCode = request.MallCode?.Trim()?.ToUpperInvariant();
        entity.MallNumber = request.MallNumber;
        entity.Active = request.Active;

        await dbContext.SaveChangesAsync();
        return Ok(MallDto.FromEntity(entity));
    }

    [HttpPost("{mallId}/deactivate")]
    [Authorize(Roles = "admin,super_admin")]
    public async Task<IActionResult> Deactivate(string mallId)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        var entity = await dbContext.Malls.FirstOrDefaultAsync(x => x.MallId == normalizedMallId);

        if (entity is null)
        {
            return NotFound(new { message = "Mall not found." });
        }

        entity.IsActive = false;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpPut("{mallId}/billing-settings")]
    [Authorize(Roles = "manager")]
    public async Task<ActionResult<MallDto>> UpdateBillingSettings(
        string mallId,
        UpdateBillingSettingsRequest request)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var entity = await dbContext.Malls.FirstOrDefaultAsync(x => x.MallId == normalizedMallId);
        if (entity is null)
        {
            return NotFound(new { message = "Mall not found." });
        }

        entity.GstPercent = request.GstPercent;
        entity.TaxLabel = string.IsNullOrWhiteSpace(request.TaxLabel) ? "Tax" : request.TaxLabel.Trim();
        entity.TaxPercent = request.TaxPercent;
        entity.ExtraChargeLabel = string.IsNullOrWhiteSpace(request.ExtraChargeLabel)
            ? "Extra Charges"
            : request.ExtraChargeLabel.Trim();
        entity.ExtraChargeAmount = request.ExtraChargeAmount;

        await dbContext.SaveChangesAsync();
        return Ok(MallDto.FromEntity(entity));
    }

    private bool CanAccessMall(string mallId)
    {
        if (User.IsInRole("admin") || User.IsInRole("super_admin"))
        {
            return true;
        }

        return string.Equals(
            User.FindFirstValue("mall_id"),
            mallId,
            StringComparison.OrdinalIgnoreCase);
    }
}
