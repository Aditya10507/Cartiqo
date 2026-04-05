namespace SwiftCart.Api.Models.Entities;

public sealed class MallEntity
{
    public string MallId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string? OwnerEmail { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public DateTime SubscriptionStartDate { get; set; }
    public DateTime SubscriptionEndDate { get; set; }
    public string PlanType { get; set; } = "basic";
    public int MaxProducts { get; set; } = 1000;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? AreaCode { get; set; }
    public int? EstYear { get; set; }
    public string? MallCode { get; set; }
    public int? MallNumber { get; set; }
    public bool? Active { get; set; }
    public decimal GstPercent { get; set; }
    public string TaxLabel { get; set; } = "Tax";
    public decimal TaxPercent { get; set; }
    public string ExtraChargeLabel { get; set; } = "Extra Charges";
    public decimal ExtraChargeAmount { get; set; }
}
