using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Managers;

public sealed class MallManagerDto
{
    public string MallId { get; set; } = string.Empty;
    public string ManagerId { get; set; } = string.Empty;
    public string? AssignedUid { get; set; }
    public string? AssignedEmail { get; set; }
    public bool IsActive { get; set; } = true;
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public DateTime? DateOfJoining { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public DateTime? PasswordUpdatedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? LinkedAt { get; set; }

    public static MallManagerDto FromEntity(MallManagerEntity entity)
    {
        return new MallManagerDto
        {
            MallId = entity.MallId,
            ManagerId = entity.ManagerId,
            AssignedUid = entity.AssignedUid,
            AssignedEmail = entity.AssignedEmail,
            IsActive = entity.IsActive,
            FullName = entity.FullName,
            PhoneNumber = entity.PhoneNumber,
            DateOfJoining = entity.DateOfJoining,
            LastLoginAt = entity.LastLoginAt,
            PasswordUpdatedAt = entity.PasswordUpdatedAt,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt,
            LinkedAt = entity.LinkedAt,
        };
    }
}
