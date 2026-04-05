using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Payments;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "admin,super_admin,manager")]
public sealed class PaymentsController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet("recent")]
    public async Task<ActionResult<List<PaymentDto>>> GetRecentPayments()
    {
        var payments = await dbContext.Payments
            .AsNoTracking()
            .OrderByDescending(x => x.CreatedAt)
            .Take(20)
            .ToListAsync();

        return Ok(payments.Select(PaymentDto.FromEntity).ToList());
    }

    [HttpGet("malls/{mallId}")]
    public async Task<ActionResult<List<PaymentDto>>> GetMallPayments(string mallId)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var payments = await dbContext.Payments
            .AsNoTracking()
            .Where(x => x.MallId == normalizedMallId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(payments.Select(PaymentDto.FromEntity).ToList());
    }

    [HttpGet("users/{userId}")]
    public async Task<ActionResult<List<PaymentDto>>> GetUserPayments(string userId)
    {
        var normalizedUserId = userId.Trim();
        var payments = await dbContext.Payments
            .AsNoTracking()
            .Where(x => x.UserId == normalizedUserId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(payments.Select(PaymentDto.FromEntity).ToList());
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
