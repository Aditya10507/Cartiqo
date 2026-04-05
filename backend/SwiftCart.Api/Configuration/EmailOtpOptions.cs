namespace SwiftCart.Api.Configuration;

public sealed class EmailOtpOptions
{
    public const string SectionName = "EmailOtp";

    public bool EnableEmailSending { get; set; }
    public bool IncludeOtpInDevelopmentResponse { get; set; } = true;
    public string SmtpHost { get; set; } = string.Empty;
    public int SmtpPort { get; set; } = 587;
    public bool UseSsl { get; set; } = true;
    public string SmtpUsername { get; set; } = string.Empty;
    public string SmtpPassword { get; set; } = string.Empty;
    public string FromAddress { get; set; } = string.Empty;
    public string FromName { get; set; } = "SwiftCart";
    public int OtpExpiryMinutes { get; set; } = 10;
    public int MaxAttempts { get; set; } = 5;
}
