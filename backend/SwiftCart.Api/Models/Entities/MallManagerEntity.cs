namespace SwiftCart.Api.Models.Entities;

public sealed class MallManagerEntity
{
    public string ManagerId { get; set; } = string.Empty;
    public string MallId { get; set; } = string.Empty;
    public string? AssignedUid { get; set; }
    public string? AssignedEmail { get; set; }
    public bool IsActive { get; set; } = true;
    public string PasswordHash { get; set; } = string.Empty;
    public DateTime? PasswordUpdatedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LinkedAt { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public DateTime? DateOfJoining { get; set; }
    public DateTime? LastLoginAt { get; set; }
}
