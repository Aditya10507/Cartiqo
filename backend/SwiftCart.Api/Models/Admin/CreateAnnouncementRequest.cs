namespace SwiftCart.Api.Models.Admin;

public sealed class CreateAnnouncementRequest
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Audience { get; set; } = "all";
    public string CreatedBy { get; set; } = string.Empty;
}
