using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SwiftCart.Api.Configuration;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Auth;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Models.Managers;
using SwiftCart.Api.Services;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/auth/mall-manager")]
public sealed class MallManagerAuthController(
    SwiftCartDbContext dbContext,
    JwtTokenService jwtTokenService,
    UserEmailOtpSender userEmailOtpSender,
    IOptions<EmailOtpOptions> emailOtpOptions) : ControllerBase
{
    private readonly EmailOtpOptions _emailOtpOptions = emailOtpOptions.Value;

    [HttpPost("request-otp")]
    [AllowAnonymous]
    public async Task<ActionResult<UserEmailOtpRequestResponse>> RequestOtp(
        MallManagerEmailOtpRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(email))
        {
            return BadRequest(new { message = "Registered manager email is required." });
        }

        var matches = await dbContext.MallManagers
            .Where(x => x.AssignedEmail != null && x.AssignedEmail.ToLower() == email)
            .Where(x => x.IsActive)
            .ToListAsync();

        if (matches.Count == 0)
        {
            return NotFound(new { message = "No active manager account found for that email." });
        }

        if (matches.Count > 1)
        {
            return Conflict(new { message = "Multiple manager accounts are linked to this email. Please contact admin support." });
        }

        var manager = matches[0];
        var otp = Random.Shared.Next(100000, 999999).ToString();
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_emailOtpOptions.OtpExpiryMinutes);

        var entity = await dbContext.MallManagerEmailOtps.FirstOrDefaultAsync(x => x.Email == email);
        var isNew = entity is null;
        entity ??= new MallManagerEmailOtpEntity
        {
            Email = email,
            CreatedAtUtc = DateTime.UtcNow,
        };

        entity.ManagerId = manager.ManagerId;
        entity.OtpCode = otp;
        entity.Attempts = 0;
        entity.ExpiresAtUtc = expiresAtUtc;
        entity.UpdatedAtUtc = DateTime.UtcNow;

        if (isNew)
        {
            dbContext.MallManagerEmailOtps.Add(entity);
        }

        await dbContext.SaveChangesAsync();

        string? debugOtp = null;
        try
        {
            var emailSent = await userEmailOtpSender.TrySendOtpAsync(
                email,
                string.IsNullOrWhiteSpace(manager.FullName) ? manager.ManagerId : manager.FullName,
                otp);
            if (!emailSent && _emailOtpOptions.IncludeOtpInDevelopmentResponse)
            {
                debugOtp = otp;
            }
        }
        catch (Exception ex)
        {
            if (!_emailOtpOptions.IncludeOtpInDevelopmentResponse)
            {
                return StatusCode(500, new { message = $"Unable to send OTP email: {ex.Message}" });
            }

            debugOtp = otp;
        }

        return Ok(new UserEmailOtpRequestResponse
        {
            Message = debugOtp is null
                ? "Verification code sent to manager email."
                : "Verification code generated for development.",
            ExpiresAtUtc = expiresAtUtc,
            DebugOtp = debugOtp,
        });
    }

    [HttpPost("verify-otp")]
    [AllowAnonymous]
    public async Task<ActionResult<MallManagerAuthResponse>> VerifyOtp(
        MallManagerEmailOtpVerifyRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var otp = request.Otp.Trim();

        if (string.IsNullOrWhiteSpace(email))
        {
            return BadRequest(new { message = "Registered manager email is required." });
        }

        if (otp.Length != 6 || !otp.All(char.IsDigit))
        {
            return BadRequest(new { message = "OTP must be a 6-digit code." });
        }

        var otpEntity = await dbContext.MallManagerEmailOtps.FirstOrDefaultAsync(x => x.Email == email);
        if (otpEntity is null)
        {
            return NotFound(new { message = "OTP not found. Request a new code first." });
        }

        if (otpEntity.ExpiresAtUtc < DateTime.UtcNow)
        {
            dbContext.MallManagerEmailOtps.Remove(otpEntity);
            await dbContext.SaveChangesAsync();
            return BadRequest(new { message = "OTP expired. Request a new code." });
        }

        if (otpEntity.Attempts >= _emailOtpOptions.MaxAttempts)
        {
            dbContext.MallManagerEmailOtps.Remove(otpEntity);
            await dbContext.SaveChangesAsync();
            return BadRequest(new { message = "Too many incorrect attempts. Request a new code." });
        }

        if (!string.Equals(otpEntity.OtpCode, otp, StringComparison.Ordinal))
        {
            otpEntity.Attempts += 1;
            otpEntity.UpdatedAtUtc = DateTime.UtcNow;
            await dbContext.SaveChangesAsync();

            var attemptsLeft = Math.Max(0, _emailOtpOptions.MaxAttempts - otpEntity.Attempts);
            return BadRequest(new { message = $"Incorrect OTP. {attemptsLeft} attempts remaining." });
        }

        var manager = await dbContext.MallManagers.FirstOrDefaultAsync(x => x.ManagerId == otpEntity.ManagerId);
        if (manager is null)
        {
            dbContext.MallManagerEmailOtps.Remove(otpEntity);
            await dbContext.SaveChangesAsync();
            return NotFound(new { message = "Manager account not found." });
        }

        if (!manager.IsActive)
        {
            dbContext.MallManagerEmailOtps.Remove(otpEntity);
            await dbContext.SaveChangesAsync();
            return BadRequest(new { message = "Manager account is disabled." });
        }

        var mall = await dbContext.Malls.FirstOrDefaultAsync(x => x.MallId == manager.MallId);
        if (mall is null)
        {
            dbContext.MallManagerEmailOtps.Remove(otpEntity);
            await dbContext.SaveChangesAsync();
            return NotFound(new { message = "Mall not found for this manager." });
        }

        manager.LastLoginAt = DateTime.UtcNow;
        manager.UpdatedAt = DateTime.UtcNow;
        dbContext.MallManagerEmailOtps.Remove(otpEntity);
        await dbContext.SaveChangesAsync();

        return Ok(jwtTokenService.CreateMallManagerToken(manager, mall));
    }
}
