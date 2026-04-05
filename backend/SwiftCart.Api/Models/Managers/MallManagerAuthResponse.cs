using SwiftCart.Api.Models.Malls;

namespace SwiftCart.Api.Models.Managers;

public sealed class MallManagerAuthResponse
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; set; }
    public MallManagerSessionDto Manager { get; set; } = new();
    public MallDto Mall { get; set; } = new();
}
