namespace SwiftCart.Api.Models.Products;

public sealed class BulkImportProductsRequest
{
    public List<UpsertProductRequest> Products { get; set; } = [];
}
