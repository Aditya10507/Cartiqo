using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Admin;

public sealed class AnnouncementDto
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Audience { get; set; } = "all";
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime? CreatedAt { get; set; }

    public static AnnouncementDto FromEntity(AnnouncementEntity entity)
    {
        return new AnnouncementDto
        {
            Id = entity.Id,
            Title = entity.Title,
            Message = entity.Message,
            Audience = entity.Audience,
            CreatedBy = entity.CreatedBy,
            CreatedAt = entity.CreatedAt,
        };
    }
}
