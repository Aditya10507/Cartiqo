namespace SwiftCart.Api.Models.Managers;

public sealed class MallManagerSessionDto
{
    public string MallId { get; set; } = string.Empty;
    public string ManagerId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public DateTime? DateOfJoining { get; set; }
    public bool IsActive { get; set; }
}
