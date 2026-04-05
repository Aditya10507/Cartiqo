namespace SwiftCart.Api.Models.Managers;

public sealed class MallManagerLoginRequest
{
    public string ManagerId { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
