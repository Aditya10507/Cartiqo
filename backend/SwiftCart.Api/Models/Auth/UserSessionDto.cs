namespace SwiftCart.Api.Models.Auth;

public sealed class UserSessionDto
{
    public string Uid { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string PhotoUrl { get; set; } = string.Empty;
    public bool EmailVerified { get; set; }
    public string Provider { get; set; } = string.Empty;
}
