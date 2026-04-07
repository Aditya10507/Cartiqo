using System.Net.Mail;
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
[AllowAnonymous]
public sealed class MallManagerAuthController(
    SwiftCartDbContext dbContext,
    JwtTokenService jwtTokenService,
    UserEmailOtpSender userEmailOtpSender,
    PasswordHashService passwordHashService,
    IOptions<EmailOtpOptions> emailOtpOptions) : ControllerBase
{
    private readonly EmailOtpOptions _emailOtpOptions = emailOtpOptions.Value;

    [HttpPost("register/request-otp")]
    public async Task<ActionResult<UserEmailOtpRequestResponse>> RequestSignupOtp(
        MallManagerSignupRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var validationError = ValidateEmailAndPassword(
            email,
            request.Password,
            request.ConfirmPassword);

        if (validationError is not null)
        {
            return BadRequest(new { message = validationError });
        }

        var manager = await dbContext.MallManagers
            .FirstOrDefaultAsync(x =>
                x.AssignedEmail != null &&
                x.AssignedEmail.ToLower() == email &&
                x.IsActive);

        if (manager is null)
        {
            return NotFound(new { message = "No active manager account found for that email." });
        }

        if (!string.IsNullOrWhiteSpace(manager.PasswordHash))
        {
            return Conflict(new { message = "This manager account is already set up. Please sign in." });
        }

        var otp = GenerateOtp();
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_emailOtpOptions.OtpExpiryMinutes);
        var passwordHash = passwordHashService.ComputeSha256(request.Password);

        var entity = await dbContext.MallManagerEmailOtps.FirstOrDefaultAsync(x => x.Email == email);
        var isNew = entity is null;
        entity ??= new MallManagerEmailOtpEntity
        {
            Email = email,
            CreatedAtUtc = DateTime.UtcNow,
        };

        entity.ManagerId = manager.ManagerId;
        entity.PendingPasswordHash = passwordHash;
        entity.OtpCode = otp;
        entity.Attempts = 0;
        entity.ExpiresAtUtc = expiresAtUtc;
        entity.UpdatedAtUtc = DateTime.UtcNow;

        if (isNew)
        {
            dbContext.MallManagerEmailOtps.Add(entity);
        }

        await dbContext.SaveChangesAsync();

        return Ok(await SendOtpResponse(
            email,
            string.IsNullOrWhiteSpace(manager.FullName) ? manager.ManagerId : manager.FullName,
            otp,
            expiresAtUtc,
            "Verification code sent to manager email.",
            "Verification code generated for development."));
    }

    [HttpPost("register/verify-otp")]
    public async Task<ActionResult<MallManagerAuthResponse>> VerifySignupOtp(
        MallManagerEmailOtpVerifyRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var otp = request.Otp.Trim();

        var validationResult = await ValidateOtpEntity(
            email,
            otp,
            dbContext.MallManagerEmailOtps,
            "OTP not found. Request a new code first.");

        if (validationResult.ErrorResult is not null)
        {
            return validationResult.ErrorResult;
        }

        var otpEntity = validationResult.Entity!;
        var manager = await dbContext.MallManagers.FirstOrDefaultAsync(
            x => x.ManagerId == otpEntity.ManagerId);

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

        manager.PasswordHash = otpEntity.PendingPasswordHash;
        manager.PasswordUpdatedAt = DateTime.UtcNow;
        manager.LastLoginAt = DateTime.UtcNow;
        manager.UpdatedAt = DateTime.UtcNow;

        var mall = await dbContext.Malls.FirstOrDefaultAsync(x => x.MallId == manager.MallId);
        if (mall is null)
        {
            dbContext.MallManagerEmailOtps.Remove(otpEntity);
            await dbContext.SaveChangesAsync();
            return NotFound(new { message = "Mall not found for this manager." });
        }

        dbContext.MallManagerEmailOtps.Remove(otpEntity);
        await dbContext.SaveChangesAsync();

        return Ok(jwtTokenService.CreateMallManagerToken(manager, mall));
    }

    [HttpPost("login")]
    public async Task<ActionResult<MallManagerAuthResponse>> Login(
        MallManagerLoginRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var password = request.Password;

        if (!IsValidEmail(email))
        {
            return BadRequest(new { message = "A valid email address is required." });
        }

        if (string.IsNullOrWhiteSpace(password))
        {
            return BadRequest(new { message = "Password is required." });
        }

        var manager = await dbContext.MallManagers.FirstOrDefaultAsync(
            x => x.AssignedEmail != null &&
                 x.AssignedEmail.ToLower() == email &&
                 x.IsActive);

        if (manager is null || string.IsNullOrWhiteSpace(manager.PasswordHash))
        {
            return Unauthorized(new { message = "Invalid email or password." });
        }

        var passwordHash = passwordHashService.ComputeSha256(password);
        if (!string.Equals(passwordHash, manager.PasswordHash, StringComparison.Ordinal))
        {
            return Unauthorized(new { message = "Invalid email or password." });
        }

        var mall = await dbContext.Malls.FirstOrDefaultAsync(x => x.MallId == manager.MallId);
        if (mall is null)
        {
            return NotFound(new { message = "Mall not found for this manager." });
        }

        manager.LastLoginAt = DateTime.UtcNow;
        manager.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return Ok(jwtTokenService.CreateMallManagerToken(manager, mall));
    }

    [HttpPost("password/request-otp")]
    public async Task<ActionResult<UserEmailOtpRequestResponse>> RequestPasswordResetOtp(
        MallManagerPasswordResetRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (!IsValidEmail(email))
        {
            return BadRequest(new { message = "A valid email address is required." });
        }

        var manager = await dbContext.MallManagers.FirstOrDefaultAsync(
            x => x.AssignedEmail != null &&
                 x.AssignedEmail.ToLower() == email &&
                 x.IsActive);

        if (manager is null)
        {
            return NotFound(new { message = "No active manager account found for that email." });
        }

        var otp = GenerateOtp();
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_emailOtpOptions.OtpExpiryMinutes);

        var entity = await dbContext.MallManagerPasswordResetOtps.FirstOrDefaultAsync(x => x.Email == email);
        var isNew = entity is null;
        entity ??= new MallManagerPasswordResetOtpEntity
        {
            Email = email,
            CreatedAtUtc = DateTime.UtcNow,
        };

        entity.OtpCode = otp;
        entity.Attempts = 0;
        entity.ExpiresAtUtc = expiresAtUtc;
        entity.UpdatedAtUtc = DateTime.UtcNow;

        if (isNew)
        {
            dbContext.MallManagerPasswordResetOtps.Add(entity);
        }

        await dbContext.SaveChangesAsync();

        return Ok(await SendOtpResponse(
            email,
            string.IsNullOrWhiteSpace(manager.FullName) ? manager.ManagerId : manager.FullName,
            otp,
            expiresAtUtc,
            "Password reset code sent to manager email.",
            "Password reset code generated for development."));
    }

    [HttpPost("password/reset")]
    public async Task<IActionResult> ResetPassword(
        MallManagerPasswordResetConfirmRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var otp = request.Otp.Trim();

        if (!IsValidEmail(email))
        {
            return BadRequest(new { message = "A valid email address is required." });
        }

        if (request.NewPassword != request.ConfirmPassword)
        {
            return BadRequest(new { message = "Password and confirm password must match." });
        }

        if (!IsValidPassword(request.NewPassword))
        {
            return BadRequest(new { message = "Password must be 8-15 characters and include uppercase, lowercase, number, and special character." });
        }

        var manager = await dbContext.MallManagers.FirstOrDefaultAsync(
            x => x.AssignedEmail != null &&
                 x.AssignedEmail.ToLower() == email &&
                 x.IsActive);

        if (manager is null)
        {
            return NotFound(new { message = "No active manager account found for that email." });
        }

        var validationResult = await ValidateOtpEntity(
            email,
            otp,
            dbContext.MallManagerPasswordResetOtps,
            "OTP not found. Request a new code first.");

        if (validationResult.ErrorResult is not null)
        {
            return validationResult.ErrorResult;
        }

        var otpEntity = validationResult.Entity!;
        manager.PasswordHash = passwordHashService.ComputeSha256(request.NewPassword);
        manager.PasswordUpdatedAt = DateTime.UtcNow;
        manager.UpdatedAt = DateTime.UtcNow;

        dbContext.MallManagerPasswordResetOtps.Remove(otpEntity);
        await dbContext.SaveChangesAsync();

        return Ok(new { message = "Password reset successful. Please sign in with your new password." });
    }

    private async Task<UserEmailOtpRequestResponse> SendOtpResponse(
        string email,
        string displayName,
        string otp,
        DateTime expiresAtUtc,
        string successMessage,
        string fallbackMessage)
    {
        string? debugOtp = null;
        try
        {
            var emailSent = await userEmailOtpSender.TrySendOtpAsync(email, displayName, otp);
            if (!emailSent && _emailOtpOptions.IncludeOtpInDevelopmentResponse)
            {
                debugOtp = otp;
            }
        }
        catch
        {
            if (_emailOtpOptions.IncludeOtpInDevelopmentResponse)
            {
                debugOtp = otp;
            }
            else
            {
                throw;
            }
        }

        return new UserEmailOtpRequestResponse
        {
            Message = debugOtp is null ? successMessage : fallbackMessage,
            ExpiresAtUtc = expiresAtUtc,
            DebugOtp = debugOtp,
        };
    }

    private async Task<(TEntity? Entity, ActionResult? ErrorResult)> ValidateOtpEntity<TEntity>(
        string email,
        string otp,
        DbSet<TEntity> dbSet,
        string missingMessage)
        where TEntity : class
    {
        if (!IsValidEmail(email))
        {
            return (null, BadRequest(new { message = "A valid email address is required." }));
        }

        if (otp.Length != 6 || !otp.All(char.IsDigit))
        {
            return (null, BadRequest(new { message = "OTP must be a 6-digit code." }));
        }

        dynamic? entity = await dbSet.FindAsync(email);
        if (entity is null)
        {
            return (null, NotFound(new { message = missingMessage }));
        }

        if (entity.ExpiresAtUtc < DateTime.UtcNow)
        {
            dbSet.Remove(entity);
            await dbContext.SaveChangesAsync();
            return (null, BadRequest(new { message = "OTP expired. Request a new code." }));
        }

        if (entity.Attempts >= _emailOtpOptions.MaxAttempts)
        {
            dbSet.Remove(entity);
            await dbContext.SaveChangesAsync();
            return (null, BadRequest(new { message = "Too many incorrect attempts. Request a new code." }));
        }

        if (!string.Equals((string)entity.OtpCode, otp, StringComparison.Ordinal))
        {
            entity.Attempts += 1;
            entity.UpdatedAtUtc = DateTime.UtcNow;
            await dbContext.SaveChangesAsync();

            var attemptsLeft = Math.Max(0, _emailOtpOptions.MaxAttempts - (int)entity.Attempts);
            return (null, BadRequest(new { message = $"Incorrect OTP. {attemptsLeft} attempts remaining." }));
        }

        return ((TEntity)entity, null);
    }

    private static string? ValidateEmailAndPassword(
        string email,
        string password,
        string confirmPassword)
    {
        if (!IsValidEmail(email))
        {
            return "A valid email address is required.";
        }

        if (password != confirmPassword)
        {
            return "Password and confirm password must match.";
        }

        if (!IsValidPassword(password))
        {
            return "Password must be 8-15 characters and include uppercase, lowercase, number, and special character.";
        }

        return null;
    }

    private static bool IsValidEmail(string email)
    {
        try
        {
            _ = new MailAddress(email);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static bool IsValidPassword(string password)
    {
        if (password.Length < 8 || password.Length > 15)
        {
            return false;
        }

        var hasUpper = password.Any(char.IsUpper);
        var hasLower = password.Any(char.IsLower);
        var hasDigit = password.Any(char.IsDigit);
        var hasSpecial = password.Any(ch => !char.IsLetterOrDigit(ch));

        return hasUpper && hasLower && hasDigit && hasSpecial;
    }

    private static string GenerateOtp() => Random.Shared.Next(100000, 999999).ToString();
}
