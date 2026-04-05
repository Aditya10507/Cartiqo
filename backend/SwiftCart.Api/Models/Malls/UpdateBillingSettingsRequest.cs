namespace SwiftCart.Api.Models.Malls;

public sealed class UpdateBillingSettingsRequest
{
    public decimal GstPercent { get; set; }
    public string TaxLabel { get; set; } = "Tax";
    public decimal TaxPercent { get; set; }
    public string ExtraChargeLabel { get; set; } = "Extra Charges";
    public decimal ExtraChargeAmount { get; set; }
}
