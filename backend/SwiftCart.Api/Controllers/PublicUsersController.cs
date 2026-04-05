using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Bills;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Models.Payments;
using SwiftCart.Api.Models.Public;
using SwiftCart.Api.Models.Users;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/public/users/{uid}")]
[AllowAnonymous]
public sealed class PublicUsersController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<UserProfileDto>> GetProfile(string uid)
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

    [HttpPut]
    public async Task<ActionResult<UserProfileDto>> UpsertProfile(
        string uid,
        PublicUserProfileUpsertRequest request)
    {
        var normalizedUid = uid.Trim();
        if (!string.Equals(normalizedUid, request.Uid.Trim(), StringComparison.Ordinal))
        {
            return BadRequest(new { message = "User ID mismatch." });
        }

        var entity = await dbContext.UserProfiles.FirstOrDefaultAsync(x => x.Uid == normalizedUid);
        var isNew = entity is null;
        entity ??= new UserProfileEntity
        {
            Uid = normalizedUid,
            CreatedAt = DateTime.UtcNow,
        };

        entity.Username = string.IsNullOrWhiteSpace(request.Username)
            ? entity.Username
            : request.Username.Trim().ToLowerInvariant();
        entity.FullName = request.FullName.Trim();
        entity.DisplayName = request.DisplayName.Trim();
        entity.Email = request.Email.Trim();
        entity.Phone = request.Phone.Trim();
        entity.PhotoUrl = request.PhotoUrl.Trim();
        entity.LocalPhotoPath = request.LocalPhotoPath.Trim();
        entity.AvatarPreset = string.IsNullOrWhiteSpace(request.AvatarPreset)
            ? "sky"
            : request.AvatarPreset.Trim();
        entity.Provider = request.Provider.Trim();
        entity.EmailVerified = request.EmailVerified;
        entity.LastLoginAt = DateTime.UtcNow;
        entity.UpdatedAt = DateTime.UtcNow;

        if (isNew)
        {
            dbContext.UserProfiles.Add(entity);
        }

        await dbContext.SaveChangesAsync();
        return Ok(UserProfileDto.FromEntity(entity));
    }

    [HttpGet("bills")]
    public async Task<ActionResult<List<BillDto>>> GetBills(string uid)
    {
        var normalizedUid = uid.Trim();
        var bills = await dbContext.Bills
            .AsNoTracking()
            .Where(x => x.UserId == normalizedUid)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(bills.Select(BillDto.FromEntity).ToList());
    }

    [HttpGet("payments")]
    public async Task<ActionResult<List<PaymentDto>>> GetPayments(string uid)
    {
        var normalizedUid = uid.Trim();
        var payments = await dbContext.Payments
            .AsNoTracking()
            .Where(x => x.UserId == normalizedUid)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(payments.Select(PaymentDto.FromEntity).ToList());
    }
}
