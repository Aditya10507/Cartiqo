namespace SwiftCart.Api.Models.Auth;

public sealed class UserEmailOtpRequestResponse
{
    public string Message { get; set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; set; }
    public string? DebugOtp { get; set; }
}
