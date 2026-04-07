namespace SwiftCart.Api.Models.Managers;

public sealed class MallManagerPasswordResetConfirmRequest
{
    public string Email { get; set; } = string.Empty;
    public string Otp { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
    public string ConfirmPassword { get; set; } = string.Empty;
}
