namespace SwiftCart.Api.Models.Entities;

public sealed class AnnouncementEntity
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Audience { get; set; } = "all";
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime? CreatedAt { get; set; }
}
