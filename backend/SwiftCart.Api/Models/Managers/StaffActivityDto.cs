using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Managers;

public sealed class StaffActivityDto
{
    public string Id { get; set; } = string.Empty;
    public string MallId { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string Details { get; set; } = string.Empty;
    public string ManagerId { get; set; } = string.Empty;
    public string ManagerEmail { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    public static StaffActivityDto FromEntity(StaffActivityEntity entity)
    {
        return new StaffActivityDto
        {
            Id = entity.Id,
            MallId = entity.MallId,
            Action = entity.Action,
            Details = entity.Details,
            ManagerId = entity.ManagerId,
            ManagerEmail = entity.ManagerEmail,
            CreatedAt = entity.CreatedAt,
        };
    }
}
