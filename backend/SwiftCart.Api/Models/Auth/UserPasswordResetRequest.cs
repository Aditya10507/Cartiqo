namespace SwiftCart.Api.Models.Auth;

public sealed class UserPasswordResetRequest
{
    public string Email { get; set; } = string.Empty;
}
