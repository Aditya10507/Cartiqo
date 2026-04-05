using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Managers;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/mall-manager/profile")]
[Authorize(Roles = "manager")]
public sealed class MallManagerProfileController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<MallManagerDto>> GetProfile()
    {
        var manager = await LoadCurrentManager();
        if (manager is null)
        {
            return NotFound(new { message = "Manager not found." });
        }

        return Ok(MallManagerDto.FromEntity(manager));
    }

    [HttpPut]
    public async Task<ActionResult<MallManagerDto>> UpdateProfile(UpdateMallManagerProfileRequest request)
    {
        var manager = await LoadCurrentManager();
        if (manager is null)
        {
            return NotFound(new { message = "Manager not found." });
        }

        manager.FullName = request.FullName.Trim();
        manager.PhoneNumber = request.PhoneNumber.Trim();
        manager.DateOfJoining = request.DateOfJoining;
        manager.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return Ok(MallManagerDto.FromEntity(manager));
    }

    private async Task<Models.Entities.MallManagerEntity?> LoadCurrentManager()
    {
        var managerId = User.FindFirstValue("manager_id")?.Trim().ToUpperInvariant();
        var mallId = User.FindFirstValue("mall_id")?.Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(managerId) || string.IsNullOrWhiteSpace(mallId))
        {
            return null;
        }

        return await dbContext.MallManagers.FirstOrDefaultAsync(
            x => x.ManagerId == managerId && x.MallId == mallId);
    }
}
