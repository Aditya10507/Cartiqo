namespace SwiftCart.Api.Models.Auth;

public sealed class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; set; }
    public AdminUserDto User { get; set; } = new();
}
