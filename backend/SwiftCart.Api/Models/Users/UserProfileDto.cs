using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Users;

public sealed class UserProfileDto
{
    public string Uid { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string PhotoUrl { get; set; } = string.Empty;
    public string LocalPhotoPath { get; set; } = string.Empty;
    public string AvatarPreset { get; set; } = "sky";
    public string Provider { get; set; } = string.Empty;
    public bool EmailVerified { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public static UserProfileDto FromEntity(UserProfileEntity entity)
    {
        return new UserProfileDto
        {
            Uid = entity.Uid,
            Username = entity.Username,
            FullName = entity.FullName,
            DisplayName = entity.DisplayName,
            Email = entity.Email,
            Phone = entity.Phone,
            PhotoUrl = entity.PhotoUrl,
            LocalPhotoPath = entity.LocalPhotoPath,
            AvatarPreset = entity.AvatarPreset,
            Provider = entity.Provider,
            EmailVerified = entity.EmailVerified,
            LastLoginAt = entity.LastLoginAt,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt,
        };
    }
}
