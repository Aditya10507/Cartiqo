namespace SwiftCart.Api.Models.Managers;

public sealed class CreateMallManagerRequest
{
    public string MallId { get; set; } = string.Empty;
    public string ManagerId { get; set; } = string.Empty;
}
