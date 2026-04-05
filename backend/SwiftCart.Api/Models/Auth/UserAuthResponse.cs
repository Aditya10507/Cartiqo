namespace SwiftCart.Api.Models.Auth;

public sealed class UserAuthResponse
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; set; }
    public UserSessionDto User { get; set; } = new();
}
