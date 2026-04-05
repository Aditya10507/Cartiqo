namespace SwiftCart.Api.Models.Public;

public sealed class PublicUserProfileUpsertRequest
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
}
