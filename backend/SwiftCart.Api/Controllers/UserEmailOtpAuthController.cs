using System.Net.Mail;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SwiftCart.Api.Configuration;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Auth;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Services;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/auth/users")]
[AllowAnonymous]
public sealed class UserEmailOtpAuthController(
    SwiftCartDbContext dbContext,
    JwtTokenService jwtTokenService,
    UserEmailOtpSender userEmailOtpSender,
    RefreshTokenService refreshTokenService,
    PasswordHashService passwordHashService,
    IOptions<EmailOtpOptions> emailOtpOptions) : ControllerBase
{
    private readonly EmailOtpOptions _emailOtpOptions = emailOtpOptions.Value;

    [HttpPost("register/request-otp")]
    public async Task<ActionResult<UserEmailOtpRequestResponse>> RequestOtp(UserEmailOtpRequest request)
    {
        var firstName = request.FirstName.Trim();
        var lastName = request.LastName.Trim();
        var username = request.Username.Trim().ToLowerInvariant();
        var email = request.Email.Trim().ToLowerInvariant();
        var password = request.Password;
        var fullName = $"{firstName} {lastName}".Trim();

        var validationError = ValidateSignupInput(firstName, lastName, username, email, password);
        if (validationError is not null)
        {
            return BadRequest(new { message = validationError });
        }

        var usernameTaken = await dbContext.UserProfiles.AnyAsync(x => x.Username == username);
        if (usernameTaken)
        {
            return Conflict(new { message = "That username is already taken." });
        }

        var emailTaken = await dbContext.UserProfiles.AnyAsync(x => x.Email == email);
        if (emailTaken)
        {
            return Conflict(new { message = "That email is already registered. Please sign in." });
        }

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_emailOtpOptions.OtpExpiryMinutes);
        var passwordHash = passwordHashService.HashPassword(password);

        var entity = await dbContext.UserEmailOtps.FirstOrDefaultAsync(x => x.Email == email);
        var isNew = entity is null;
        entity ??= new UserEmailOtpEntity
        {
            Email = email,
            CreatedAtUtc = DateTime.UtcNow,
        };

        entity.FirstName = firstName;
        entity.LastName = lastName;
        entity.Username = username;
        entity.FullName = fullName;
        entity.PasswordHash = passwordHash;
        entity.OtpCode = otp;
        entity.Attempts = 0;
        entity.ExpiresAtUtc = expiresAtUtc;
        entity.UpdatedAtUtc = DateTime.UtcNow;

        if (isNew)
        {
            dbContext.UserEmailOtps.Add(entity);
        }

        await dbContext.SaveChangesAsync();

        string? debugOtp = null;
        try
        {
            var emailSent = await userEmailOtpSender.TrySendOtpAsync(email, fullName, otp);
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
                ? "Verification code sent to your email."
                : "Verification code generated for development.",
            ExpiresAtUtc = expiresAtUtc,
            DebugOtp = debugOtp,
        });
    }

    [HttpPost("register/verify-otp")]
    public async Task<ActionResult<UserAuthResponse>> VerifyOtp(UserEmailOtpVerifyRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var otp = request.Otp.Trim();

        var validationResult = await ValidateOtpEntity(
            email,
            otp,
            dbContext.UserEmailOtps,
            "OTP not found. Request a new code first.");

        if (validationResult.ErrorResult is not null)
        {
            return validationResult.ErrorResult;
        }

        var otpEntity = validationResult.Entity!;

        var usernameTaken = await dbContext.UserProfiles.AnyAsync(x => x.Username == otpEntity.Username);
        if (usernameTaken)
        {
            dbContext.UserEmailOtps.Remove(otpEntity);
            await dbContext.SaveChangesAsync();
            return Conflict(new { message = "That username is already taken. Start signup again with a different username." });
        }

        var user = new UserProfileEntity
        {
            Uid = Guid.NewGuid().ToString("N"),
            Username = otpEntity.Username,
            PasswordHash = otpEntity.PasswordHash,
            FullName = otpEntity.FullName,
            DisplayName = otpEntity.FirstName,
            Email = email,
            Provider = "email_password",
            EmailVerified = true,
            LastLoginAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };

        dbContext.UserProfiles.Add(user);
        dbContext.UserEmailOtps.Remove(otpEntity);
        await dbContext.SaveChangesAsync();

        var (response, token) = jwtTokenService.CreateUserToken(user);
        await refreshTokenService.SaveRefreshTokenAsync(token);

        return Ok(response);
    }

    [HttpPost("password/request-otp")]
    public async Task<ActionResult<UserEmailOtpRequestResponse>> RequestPasswordResetOtp(
        UserPasswordResetRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(email) || !IsValidEmail(email))
        {
            return BadRequest(new { message = "A valid email address is required." });
        }

        var user = await dbContext.UserProfiles.FirstOrDefaultAsync(x => x.Email == email);
        if (user is null)
        {
            return NotFound(new { message = "No account found for that email address." });
        }

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(_emailOtpOptions.OtpExpiryMinutes);

        var entity = await dbContext.UserPasswordResetOtps.FirstOrDefaultAsync(x => x.Email == email);
        var isNew = entity is null;
        entity ??= new UserPasswordResetOtpEntity
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
            dbContext.UserPasswordResetOtps.Add(entity);
        }

        await dbContext.SaveChangesAsync();

        string? debugOtp = null;
        try
        {
            var emailSent = await userEmailOtpSender.TrySendOtpAsync(email, user.FullName, otp);
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
                ? "Password reset code sent to your email."
                : "Password reset code generated for development.",
            ExpiresAtUtc = expiresAtUtc,
            DebugOtp = debugOtp,
        });
    }

    [HttpPost("password/reset")]
    public async Task<IActionResult> ResetPassword(UserPasswordResetConfirmRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var otp = request.Otp.Trim();
        var newPassword = request.NewPassword;

        if (string.IsNullOrWhiteSpace(email) || !IsValidEmail(email))
        {
            return BadRequest(new { message = "A valid email address is required." });
        }

        if (otp.Length != 6 || !otp.All(char.IsDigit))
        {
            return BadRequest(new { message = "OTP must be a 6-digit code." });
        }

        if (!IsValidPassword(newPassword))
        {
            return BadRequest(new { message = "Password must be 8-15 characters and include uppercase, lowercase, number, and special character." });
        }

        var user = await dbContext.UserProfiles.FirstOrDefaultAsync(x => x.Email == email);
        if (user is null)
        {
            return NotFound(new { message = "No account found for that email address." });
        }

        var otpEntity = await dbContext.UserPasswordResetOtps.FirstOrDefaultAsync(x => x.Email == email);
        if (otpEntity is null)
        {
            return NotFound(new { message = "OTP not found. Request a new code first." });
        }

        if (otpEntity.ExpiresAtUtc < DateTime.UtcNow)
        {
            dbContext.UserPasswordResetOtps.Remove(otpEntity);
            await dbContext.SaveChangesAsync();
            return BadRequest(new { message = "OTP expired. Request a new code." });
        }

        if (otpEntity.Attempts >= _emailOtpOptions.MaxAttempts)
        {
            dbContext.UserPasswordResetOtps.Remove(otpEntity);
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

        user.PasswordHash = passwordHashService.HashPassword(newPassword);
        user.UpdatedAt = DateTime.UtcNow;
        dbContext.UserPasswordResetOtps.Remove(otpEntity);
        await dbContext.SaveChangesAsync();

        return Ok(new { message = "Password reset successful. Please sign in with your new password." });
    }

    private static string? ValidateSignupInput(
        string firstName,
        string lastName,
        string username,
        string email,
        string password)
    {
        if (string.IsNullOrWhiteSpace(firstName))
        {
            return "First name is required.";
        }

        if (string.IsNullOrWhiteSpace(lastName))
        {
            return "Last name is required.";
        }

        if (string.IsNullOrWhiteSpace(username) || username.Length < 4)
        {
            return "Username must be at least 4 characters.";
        }

        if (!Regex.IsMatch(username, "^[a-zA-Z0-9._]+$"))
        {
            return "Username can only include letters, numbers, dots, and underscores.";
        }

        if (string.IsNullOrWhiteSpace(email) || !IsValidEmail(email))
        {
            return "A valid email address is required.";
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
}
