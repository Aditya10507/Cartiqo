using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Admin;
using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AnnouncementsController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<AnnouncementDto>>> GetLatest()
    {
        var announcements = await dbContext.Announcements
            .AsNoTracking()
            .OrderByDescending(x => x.CreatedAt)
            .Take(20)
            .ToListAsync();

        return Ok(announcements.Select(AnnouncementDto.FromEntity).ToList());
    }

    [HttpPost]
    [Authorize(Roles = "admin,super_admin")]
    public async Task<ActionResult<AnnouncementDto>> Create(CreateAnnouncementRequest request)
    {
        var entity = new AnnouncementEntity
        {
            Id = Guid.NewGuid().ToString("N"),
            Title = request.Title.Trim(),
            Message = request.Message.Trim(),
            Audience = string.IsNullOrWhiteSpace(request.Audience) ? "all" : request.Audience.Trim(),
            CreatedBy = request.CreatedBy.Trim(),
            CreatedAt = DateTime.UtcNow,
        };

        dbContext.Announcements.Add(entity);
        await dbContext.SaveChangesAsync();
        return CreatedAtAction(nameof(GetLatest), new { id = entity.Id }, AnnouncementDto.FromEntity(entity));
    }
}
