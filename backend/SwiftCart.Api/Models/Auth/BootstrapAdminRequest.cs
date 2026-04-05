namespace SwiftCart.Api.Models.Auth;

public sealed class BootstrapAdminRequest
{
    public string SetupKey { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Role { get; set; } = "super_admin";
}
