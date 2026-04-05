using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Bills;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "admin,super_admin")]
public sealed class BillsController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet("malls/{mallId}")]
    public async Task<ActionResult<List<BillDto>>> GetMallBills(string mallId)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        var bills = await dbContext.Bills
            .AsNoTracking()
            .Where(x => x.MallId == normalizedMallId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(bills.Select(BillDto.FromEntity).ToList());
    }

    [HttpGet("users/{userId}")]
    public async Task<ActionResult<List<BillDto>>> GetUserBills(string userId)
    {
        var normalizedUserId = userId.Trim();
        var bills = await dbContext.Bills
            .AsNoTracking()
            .Where(x => x.UserId == normalizedUserId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(bills.Select(BillDto.FromEntity).ToList());
    }
}
