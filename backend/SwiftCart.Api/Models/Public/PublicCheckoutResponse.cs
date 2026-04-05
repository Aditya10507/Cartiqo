namespace SwiftCart.Api.Models.Public;

public sealed class PublicCheckoutResponse
{
    public string BillId { get; set; } = string.Empty;
    public string BillNumber { get; set; } = string.Empty;
    public string PaymentId { get; set; } = string.Empty;
    public string PaymentNumber { get; set; } = string.Empty;
}
