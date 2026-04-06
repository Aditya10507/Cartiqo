namespace SwiftCart.Api.Models.Managers;

public sealed class MallManagerEmailOtpVerifyRequest
{
    public string Email { get; set; } = string.Empty;
    public string Otp { get; set; } = string.Empty;
}
