namespace SwiftCart.Api.Models.Public;

public sealed class PublicCheckoutRequest
{
    public string MallId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public string CustomerPhone { get; set; } = string.Empty;
    public int Total { get; set; }
    public int Subtotal { get; set; }
    public int ExtraCharge { get; set; }
    public string ExtraChargeLabel { get; set; } = "Extra Charges";
    public int Gst { get; set; }
    public decimal GstPercent { get; set; }
    public int OtherTax { get; set; }
    public string OtherTaxLabel { get; set; } = "Tax";
    public decimal OtherTaxPercent { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string PaymentReference { get; set; } = string.Empty;
    public List<Dictionary<string, object?>> Items { get; set; } = [];
}
