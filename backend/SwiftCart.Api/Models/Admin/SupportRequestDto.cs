using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Admin;

public sealed class SupportRequestDto
{
    public string Id { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Status { get; set; } = "new";
    public DateTime? CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public static SupportRequestDto FromEntity(SupportRequestEntity entity)
    {
        return new SupportRequestDto
        {
            Id = entity.Id,
            Type = entity.Type,
            Name = entity.Name,
            Email = entity.Email,
            Message = entity.Message,
            Status = entity.Status,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt,
        };
    }
}
