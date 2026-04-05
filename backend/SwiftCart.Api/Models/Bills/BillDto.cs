using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Bills;

public sealed class BillDto
{
    public string BillId { get; set; } = string.Empty;
    public string BillNumber { get; set; } = string.Empty;
    public string MallId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public string CustomerPhone { get; set; } = string.Empty;
    public int Subtotal { get; set; }
    public int ExtraCharge { get; set; }
    public string ExtraChargeLabel { get; set; } = string.Empty;
    public int Gst { get; set; }
    public decimal GstPercent { get; set; }
    public int OtherTax { get; set; }
    public string OtherTaxLabel { get; set; } = string.Empty;
    public decimal OtherTaxPercent { get; set; }
    public int Total { get; set; }
    public int ItemCount { get; set; }
    public string ItemsJson { get; set; } = "[]";
    public string Status { get; set; } = string.Empty;
    public DateTime? CreatedAt { get; set; }

    public static BillDto FromEntity(BillEntity entity)
    {
        return new BillDto
        {
            BillId = entity.BillId,
            BillNumber = entity.BillNumber,
            MallId = entity.MallId,
            UserId = entity.UserId,
            CustomerName = entity.CustomerName,
            CustomerEmail = entity.CustomerEmail,
            CustomerPhone = entity.CustomerPhone,
            Subtotal = entity.Subtotal,
            ExtraCharge = entity.ExtraCharge,
            ExtraChargeLabel = entity.ExtraChargeLabel,
            Gst = entity.Gst,
            GstPercent = entity.GstPercent,
            OtherTax = entity.OtherTax,
            OtherTaxLabel = entity.OtherTaxLabel,
            OtherTaxPercent = entity.OtherTaxPercent,
            Total = entity.Total,
            ItemCount = entity.ItemCount,
            ItemsJson = entity.ItemsJson,
            Status = entity.Status,
            CreatedAt = entity.CreatedAt,
        };
    }
}
