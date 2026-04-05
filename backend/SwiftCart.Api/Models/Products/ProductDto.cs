using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Products;

public sealed class ProductDto
{
    public string ProductId { get; set; } = string.Empty;
    public string MallId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Barcode { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string ImageSourcePage { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal Weight { get; set; }
    public string WeightUnit { get; set; } = "g";
    public string Unit { get; set; } = "1 pc";
    public string Brand { get; set; } = "General";
    public string Category { get; set; } = "General";
    public int Stock { get; set; }
    public bool InStock { get; set; } = true;

    public static ProductDto FromEntity(ProductEntity entity)
    {
        return new ProductDto
        {
            ProductId = entity.ProductId,
            MallId = entity.MallId,
            Name = entity.Name,
            Barcode = entity.Barcode,
            ImageUrl = entity.ImageUrl,
            ImageSourcePage = entity.ImageSourcePage,
            Price = entity.Price,
            Weight = entity.Weight,
            WeightUnit = entity.WeightUnit,
            Unit = entity.Unit,
            Brand = entity.Brand,
            Category = entity.Category,
            Stock = entity.Stock,
            InStock = entity.InStock,
        };
    }
}
