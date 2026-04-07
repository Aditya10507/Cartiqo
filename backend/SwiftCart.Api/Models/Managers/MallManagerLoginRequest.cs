namespace SwiftCart.Api.Models.Managers;

public sealed class MallManagerLoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
