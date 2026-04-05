namespace SwiftCart.Api.Models.Entities;

public sealed class StaffActivityEntity
{
    public string Id { get; set; } = string.Empty;
    public string MallId { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string Details { get; set; } = string.Empty;
    public string ManagerId { get; set; } = string.Empty;
    public string ManagerEmail { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
