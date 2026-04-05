namespace SwiftCart.Api.Models.Public;

public sealed class PublicMallBillingSettingsDto
{
    public string MallId { get; set; } = string.Empty;
    public decimal GstPercent { get; set; }
    public string TaxLabel { get; set; } = "Tax";
    public decimal TaxPercent { get; set; }
    public string ExtraChargeLabel { get; set; } = "Extra Charges";
    public decimal ExtraChargeAmount { get; set; }
}
