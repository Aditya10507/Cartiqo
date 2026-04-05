using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Bills;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Models.Payments;
using SwiftCart.Api.Models.Products;
using SwiftCart.Api.Models.Public;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/public/malls/{mallId}")]
[AllowAnonymous]
public sealed class PublicStorefrontController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet("products")]
    public async Task<ActionResult<List<ProductDto>>> GetProducts(string mallId)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        var mallExists = await dbContext.Malls.AsNoTracking().AnyAsync(
            x => x.MallId == normalizedMallId && x.IsActive);
        if (!mallExists)
        {
            return NotFound(new { message = "Mall not found." });
        }

        var products = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.MallId == normalizedMallId)
            .OrderBy(x => x.Name)
            .ToListAsync();

        return Ok(products.Select(ProductDto.FromEntity).ToList());
    }

    [HttpGet("products/barcode/{barcode}")]
    public async Task<ActionResult<ProductDto>> GetProductByBarcode(string mallId, string barcode)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        var normalizedBarcode = barcode.Trim();

        var product = await dbContext.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(x =>
                x.MallId == normalizedMallId && x.Barcode == normalizedBarcode);

        if (product is null)
        {
            return NotFound(new { message = "Barcode not found in this mall." });
        }

        return Ok(ProductDto.FromEntity(product));
    }

    [HttpGet("billing-settings")]
    public async Task<ActionResult<PublicMallBillingSettingsDto>> GetBillingSettings(string mallId)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        var mall = await dbContext.Malls
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.MallId == normalizedMallId && x.IsActive);

        if (mall is null)
        {
            return NotFound(new { message = "Mall not found." });
        }

        return Ok(new PublicMallBillingSettingsDto
        {
            MallId = mall.MallId,
            GstPercent = mall.GstPercent,
            TaxLabel = mall.TaxLabel,
            TaxPercent = mall.TaxPercent,
            ExtraChargeLabel = mall.ExtraChargeLabel,
            ExtraChargeAmount = mall.ExtraChargeAmount,
        });
    }

    [HttpPost("checkout")]
    public async Task<ActionResult<PublicCheckoutResponse>> CompleteCheckout(
        string mallId,
        PublicCheckoutRequest request)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!string.Equals(normalizedMallId, request.MallId.Trim().ToUpperInvariant(), StringComparison.Ordinal))
        {
            return BadRequest(new { message = "Mall ID mismatch." });
        }

        var mallExists = await dbContext.Malls.AsNoTracking().AnyAsync(
            x => x.MallId == normalizedMallId && x.IsActive);
        if (!mallExists)
        {
            return NotFound(new { message = "Mall not found." });
        }

        var now = DateTime.UtcNow;
        var billId = Guid.NewGuid().ToString("N");
        var paymentId = Guid.NewGuid().ToString("N");
        var billNumber = $"BILL-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
        var paymentNumber = $"PAY-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";

        var bill = new BillEntity
        {
            BillId = billId,
            BillNumber = billNumber,
            MallId = normalizedMallId,
            UserId = request.UserId.Trim(),
            CustomerName = request.CustomerName.Trim(),
            CustomerEmail = request.CustomerEmail.Trim(),
            CustomerPhone = request.CustomerPhone.Trim(),
            Subtotal = request.Subtotal,
            ExtraCharge = request.ExtraCharge,
            ExtraChargeLabel = request.ExtraChargeLabel.Trim(),
            Gst = request.Gst,
            GstPercent = request.GstPercent,
            OtherTax = request.OtherTax,
            OtherTaxLabel = request.OtherTaxLabel.Trim(),
            OtherTaxPercent = request.OtherTaxPercent,
            Total = request.Total,
            ItemCount = request.Items.Count,
            ItemsJson = JsonSerializer.Serialize(request.Items),
            Status = "paid",
            CreatedAt = now,
        };

        var payment = new PaymentEntity
        {
            PaymentId = paymentId,
            PaymentNumber = paymentNumber,
            BillId = billId,
            BillNumber = billNumber,
            MallId = normalizedMallId,
            UserId = request.UserId.Trim(),
            CustomerName = request.CustomerName.Trim(),
            CustomerEmail = request.CustomerEmail.Trim(),
            CustomerPhone = request.CustomerPhone.Trim(),
            Amount = request.Total,
            Subtotal = request.Subtotal,
            ExtraCharge = request.ExtraCharge,
            ExtraChargeLabel = request.ExtraChargeLabel.Trim(),
            Gst = request.Gst,
            GstPercent = request.GstPercent,
            OtherTax = request.OtherTax,
            OtherTaxLabel = request.OtherTaxLabel.Trim(),
            OtherTaxPercent = request.OtherTaxPercent,
            Method = request.PaymentMethod.Trim(),
            Reference = request.PaymentReference.Trim(),
            Status = "success",
            CreatedAt = now,
        };

        dbContext.Bills.Add(bill);
        dbContext.Payments.Add(payment);
        await dbContext.SaveChangesAsync();

        return Ok(new PublicCheckoutResponse
        {
            BillId = bill.BillId,
            BillNumber = bill.BillNumber,
            PaymentId = payment.PaymentId,
            PaymentNumber = payment.PaymentNumber,
        });
    }
}
