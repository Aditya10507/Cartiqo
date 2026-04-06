namespace SwiftCart.Api.Models.Entities;

public sealed class MallManagerEmailOtpEntity
{
    public string Email { get; set; } = string.Empty;
    public string ManagerId { get; set; } = string.Empty;
    public string OtpCode { get; set; } = string.Empty;
    public int Attempts { get; set; }
    public DateTime ExpiresAtUtc { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}
