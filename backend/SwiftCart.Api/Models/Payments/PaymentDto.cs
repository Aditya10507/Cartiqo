using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Payments;

public sealed class PaymentDto
{
    public string PaymentId { get; set; } = string.Empty;
    public string PaymentNumber { get; set; } = string.Empty;
    public string BillId { get; set; } = string.Empty;
    public string BillNumber { get; set; } = string.Empty;
    public string MallId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public string CustomerPhone { get; set; } = string.Empty;
    public int Amount { get; set; }
    public int Subtotal { get; set; }
    public int ExtraCharge { get; set; }
    public string ExtraChargeLabel { get; set; } = string.Empty;
    public int Gst { get; set; }
    public decimal GstPercent { get; set; }
    public int OtherTax { get; set; }
    public string OtherTaxLabel { get; set; } = string.Empty;
    public decimal OtherTaxPercent { get; set; }
    public string Method { get; set; } = string.Empty;
    public string Reference { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? CreatedAt { get; set; }

    public static PaymentDto FromEntity(PaymentEntity entity)
    {
        return new PaymentDto
        {
            PaymentId = entity.PaymentId,
            PaymentNumber = entity.PaymentNumber,
            BillId = entity.BillId,
            BillNumber = entity.BillNumber,
            MallId = entity.MallId,
            UserId = entity.UserId,
            CustomerName = entity.CustomerName,
            CustomerEmail = entity.CustomerEmail,
            CustomerPhone = entity.CustomerPhone,
            Amount = entity.Amount,
            Subtotal = entity.Subtotal,
            ExtraCharge = entity.ExtraCharge,
            ExtraChargeLabel = entity.ExtraChargeLabel,
            Gst = entity.Gst,
            GstPercent = entity.GstPercent,
            OtherTax = entity.OtherTax,
            OtherTaxLabel = entity.OtherTaxLabel,
            OtherTaxPercent = entity.OtherTaxPercent,
            Method = entity.Method,
            Reference = entity.Reference,
            Status = entity.Status,
            CreatedAt = entity.CreatedAt,
        };
    }
}
