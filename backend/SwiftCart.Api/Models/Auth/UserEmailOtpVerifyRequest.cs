namespace SwiftCart.Api.Models.Auth;

public sealed class UserEmailOtpVerifyRequest
{
    public string Email { get; set; } = string.Empty;
    public string Otp { get; set; } = string.Empty;
}
