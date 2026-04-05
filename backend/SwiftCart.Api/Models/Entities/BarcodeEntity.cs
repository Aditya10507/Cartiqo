namespace SwiftCart.Api.Models.Entities;

public sealed class BarcodeEntity
{
    public string Barcode { get; set; } = string.Empty;
    public string MallId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string ImageSourcePage { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Unit { get; set; } = string.Empty;
    public bool InStock { get; set; } = true;
    public DateTime? UpdatedAt { get; set; }
}
