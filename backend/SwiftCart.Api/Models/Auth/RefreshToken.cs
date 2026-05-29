using System.ComponentModel.DataAnnotations;

namespace SwiftCart.Api.Models.Auth;

public sealed class RefreshToken
{
    [Key]
    public Guid Id { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    [Required]
    public string Token { get; set; } = string.Empty;

    public DateTime ExpiresAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public bool IsRevoked { get; set; }

    public bool IsActive => !IsRevoked && ExpiresAt > DateTime.UtcNow;
}
