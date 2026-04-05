using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Users;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "admin,super_admin")]
public sealed class UsersController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<UserProfileDto>>> GetAll()
    {
        var users = await dbContext.UserProfiles
            .AsNoTracking()
            .OrderBy(x => x.FullName)
            .ThenBy(x => x.Email)
            .ToListAsync();

        return Ok(users.Select(UserProfileDto.FromEntity).ToList());
    }

    [HttpGet("{uid}")]
    public async Task<ActionResult<UserProfileDto>> GetById(string uid)
    {
        var normalizedUid = uid.Trim();
        var user = await dbContext.UserProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Uid == normalizedUid);

        if (user is null)
        {
            return NotFound(new { message = "User not found." });
        }

        return Ok(UserProfileDto.FromEntity(user));
    }
}
