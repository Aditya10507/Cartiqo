using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Malls;

public sealed class MallDto
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
    public DateTime CreatedAt { get; set; }
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

    public static MallDto FromEntity(MallEntity entity)
    {
        return new MallDto
        {
            MallId = entity.MallId,
            Name = entity.Name,
            OwnerName = entity.OwnerName,
            OwnerEmail = entity.OwnerEmail,
            City = entity.City,
            State = entity.State,
            SubscriptionStartDate = entity.SubscriptionStartDate,
            SubscriptionEndDate = entity.SubscriptionEndDate,
            PlanType = entity.PlanType,
            MaxProducts = entity.MaxProducts,
            IsActive = entity.IsActive,
            CreatedAt = entity.CreatedAt,
            AreaCode = entity.AreaCode,
            EstYear = entity.EstYear,
            MallCode = entity.MallCode,
            MallNumber = entity.MallNumber,
            Active = entity.Active,
            GstPercent = entity.GstPercent,
            TaxLabel = entity.TaxLabel,
            TaxPercent = entity.TaxPercent,
            ExtraChargeLabel = entity.ExtraChargeLabel,
            ExtraChargeAmount = entity.ExtraChargeAmount,
        };
    }

    public MallEntity ToEntity()
    {
        return new MallEntity
        {
            MallId = MallId.Trim().ToUpperInvariant(),
            Name = Name.Trim(),
            OwnerName = OwnerName?.Trim(),
            OwnerEmail = OwnerEmail?.Trim(),
            City = City?.Trim(),
            State = State?.Trim(),
            SubscriptionStartDate = SubscriptionStartDate,
            SubscriptionEndDate = SubscriptionEndDate,
            PlanType = PlanType.Trim(),
            MaxProducts = MaxProducts,
            IsActive = IsActive,
            CreatedAt = CreatedAt == default ? DateTime.UtcNow : CreatedAt,
            AreaCode = AreaCode?.Trim(),
            EstYear = EstYear,
            MallCode = MallCode?.Trim()?.ToUpperInvariant(),
            MallNumber = MallNumber,
            Active = Active,
            GstPercent = GstPercent,
            TaxLabel = string.IsNullOrWhiteSpace(TaxLabel) ? "Tax" : TaxLabel.Trim(),
            TaxPercent = TaxPercent,
            ExtraChargeLabel = string.IsNullOrWhiteSpace(ExtraChargeLabel)
                ? "Extra Charges"
                : ExtraChargeLabel.Trim(),
            ExtraChargeAmount = ExtraChargeAmount,
        };
    }
}
