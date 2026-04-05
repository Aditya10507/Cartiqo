using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;
using SwiftCart.Api.Configuration;

namespace SwiftCart.Api.Services;

public sealed class UserEmailOtpSender(
    IOptions<EmailOtpOptions> options,
    ILogger<UserEmailOtpSender> logger)
{
    private readonly EmailOtpOptions _options = options.Value;

    public async Task<bool> TrySendOtpAsync(string email, string fullName, string otp)
    {
        if (!_options.EnableEmailSending || string.IsNullOrWhiteSpace(_options.SmtpHost))
        {
            logger.LogInformation(
                "Email OTP sending is disabled or not configured. OTP for {Email}: {Otp}",
                email,
                otp);
            return false;
        }

        using var message = new MailMessage
        {
            From = new MailAddress(_options.FromAddress, _options.FromName),
            Subject = "SwiftCart email verification code",
            Body = BuildBody(fullName, otp, _options.OtpExpiryMinutes),
            IsBodyHtml = false,
        };

        message.To.Add(email);

        using var client = new SmtpClient(_options.SmtpHost, _options.SmtpPort)
        {
            EnableSsl = _options.UseSsl,
            DeliveryMethod = SmtpDeliveryMethod.Network,
            UseDefaultCredentials = false,
            Credentials = string.IsNullOrWhiteSpace(_options.SmtpUsername)
                ? CredentialCache.DefaultNetworkCredentials
                : new NetworkCredential(_options.SmtpUsername, _options.SmtpPassword),
        };

        await client.SendMailAsync(message);
        return true;
    }

    private static string BuildBody(string fullName, string otp, int expiryMinutes)
    {
        var safeName = string.IsNullOrWhiteSpace(fullName) ? "there" : fullName.Trim();
        return
            $"Hi {safeName},{Environment.NewLine}{Environment.NewLine}" +
            $"Your SwiftCart verification code is: {otp}{Environment.NewLine}{Environment.NewLine}" +
            $"This code expires in {expiryMinutes} minutes.{Environment.NewLine}{Environment.NewLine}" +
            "If you did not request this code, you can ignore this email.";
    }
}
