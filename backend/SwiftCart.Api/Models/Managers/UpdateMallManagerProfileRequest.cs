namespace SwiftCart.Api.Models.Managers;

public sealed class UpdateMallManagerProfileRequest
{
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public DateTime? DateOfJoining { get; set; }
}
