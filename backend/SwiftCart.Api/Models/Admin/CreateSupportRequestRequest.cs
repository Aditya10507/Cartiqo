namespace SwiftCart.Api.Models.Admin;

public sealed class CreateSupportRequestRequest
{
    public string Type { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}
