using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Models.Managers;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/mall-manager")]
[Authorize(Roles = "manager")]
public sealed class MallManagerOperationsController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet("promotions")]
    public async Task<ActionResult<List<PromotionDto>>> GetPromotions()
    {
        var mallId = RequireMallId();
        if (mallId is null)
        {
            return Forbid();
        }

        var promotions = await dbContext.Promotions
            .AsNoTracking()
            .Where(x => x.MallId == mallId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(20)
            .ToListAsync();

        return Ok(promotions.Select(PromotionDto.FromEntity).ToList());
    }

    [HttpPost("promotions")]
    public async Task<ActionResult<PromotionDto>> SavePromotion(UpsertPromotionRequest request)
    {
        var mallId = RequireMallId();
        if (mallId is null)
        {
            return Forbid();
        }

        PromotionEntity? entity = null;
        var promotionId = request.PromotionId.Trim();
        if (!string.IsNullOrWhiteSpace(promotionId))
        {
            entity = await dbContext.Promotions.FirstOrDefaultAsync(
                x => x.Id == promotionId && x.MallId == mallId);
            if (entity is null)
            {
                return NotFound(new { message = "Promotion not found." });
            }
        }

        var isNew = entity is null;
        entity ??= new PromotionEntity
        {
            Id = Guid.NewGuid().ToString("N"),
            MallId = mallId,
            CreatedAt = DateTime.UtcNow,
        };

        entity.Title = request.Title.Trim();
        entity.Description = request.Description.Trim();
        entity.DiscountLabel = request.DiscountLabel.Trim();
        entity.StartDate = request.StartDate;
        entity.EndDate = request.EndDate;
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;

        if (isNew)
        {
            dbContext.Promotions.Add(entity);
        }

        dbContext.StaffActivities.Add(BuildActivity(
            mallId,
            isNew ? "Promotion created" : "Promotion updated",
            entity.Title));

        await dbContext.SaveChangesAsync();
        return Ok(PromotionDto.FromEntity(entity));
    }

    [HttpDelete("promotions/{promotionId}")]
    public async Task<IActionResult> DeletePromotion(string promotionId)
    {
        var mallId = RequireMallId();
        if (mallId is null)
        {
            return Forbid();
        }

        var entity = await dbContext.Promotions.FirstOrDefaultAsync(
            x => x.Id == promotionId.Trim() && x.MallId == mallId);
        if (entity is null)
        {
            return NotFound(new { message = "Promotion not found." });
        }

        dbContext.Promotions.Remove(entity);
        dbContext.StaffActivities.Add(BuildActivity(mallId, "Promotion deleted", entity.Title));
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("staff-activity")]
    public async Task<ActionResult<List<StaffActivityDto>>> GetStaffActivity()
    {
        var mallId = RequireMallId();
        if (mallId is null)
        {
            return Forbid();
        }

        var activities = await dbContext.StaffActivities
            .AsNoTracking()
            .Where(x => x.MallId == mallId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(50)
            .ToListAsync();

        return Ok(activities.Select(StaffActivityDto.FromEntity).ToList());
    }

    private string? RequireMallId()
    {
        return User.FindFirstValue("mall_id")?.Trim().ToUpperInvariant();
    }

    private StaffActivityEntity BuildActivity(string mallId, string action, string details)
    {
        return new StaffActivityEntity
        {
            Id = Guid.NewGuid().ToString("N"),
            MallId = mallId,
            Action = action,
            Details = details,
            ManagerId = User.FindFirstValue("manager_id") ?? string.Empty,
            ManagerEmail = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty,
            CreatedAt = DateTime.UtcNow,
        };
    }
}
