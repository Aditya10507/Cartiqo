using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Admin;
using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class SupportRequestsController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet]
    [Authorize(Roles = "admin,super_admin")]
    public async Task<ActionResult<List<SupportRequestDto>>> GetLatest()
    {
        var requests = await dbContext.SupportRequests
            .AsNoTracking()
            .OrderByDescending(x => x.CreatedAt)
            .Take(50)
            .ToListAsync();

        return Ok(requests.Select(SupportRequestDto.FromEntity).ToList());
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<ActionResult<SupportRequestDto>> Create(CreateSupportRequestRequest request)
    {
        var now = DateTime.UtcNow;
        var entity = new SupportRequestEntity
        {
            Id = Guid.NewGuid().ToString("N"),
            Type = request.Type.Trim(),
            Name = request.Name.Trim(),
            Email = request.Email.Trim().ToLowerInvariant(),
            Message = request.Message.Trim(),
            Status = "new",
            CreatedAt = now,
            UpdatedAt = now,
        };

        dbContext.SupportRequests.Add(entity);
        await dbContext.SaveChangesAsync();
        return CreatedAtAction(nameof(GetLatest), new { id = entity.Id }, SupportRequestDto.FromEntity(entity));
    }

    [HttpPost("{requestId}/status")]
    [Authorize(Roles = "admin,super_admin")]
    public async Task<IActionResult> UpdateStatus(
        string requestId,
        UpdateSupportRequestStatusRequest request)
    {
        var normalizedRequestId = requestId.Trim();
        var entity = await dbContext.SupportRequests.FirstOrDefaultAsync(x => x.Id == normalizedRequestId);
        if (entity is null)
        {
            return NotFound(new { message = "Support request not found." });
        }

        entity.Status = request.Status.Trim();
        entity.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }
}
