using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using SwiftCart.Api.Data;
using SwiftCart.Api.Models.Entities;
using SwiftCart.Api.Models.Products;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/malls/{mallId}/products")]
[Authorize(Roles = "admin,super_admin,manager")]
public sealed class ProductsController(SwiftCartDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<ProductDto>>> GetAll(string mallId)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var products = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.MallId == normalizedMallId)
            .OrderBy(x => x.Name)
            .ToListAsync();

        return Ok(products.Select(ProductDto.FromEntity).ToList());
    }

    [HttpGet("barcode/{barcode}")]
    public async Task<ActionResult<ProductDto>> GetByBarcode(string mallId, string barcode)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        var normalizedBarcode = barcode.Trim();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var product = await dbContext.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(x =>
                x.MallId == normalizedMallId && x.Barcode == normalizedBarcode);

        if (product is null)
        {
            return NotFound(new { message = "Product not found." });
        }

        return Ok(ProductDto.FromEntity(product));
    }

    [HttpPost]
    public async Task<ActionResult<ProductDto>> Create(string mallId, UpsertProductRequest request)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var productId = string.IsNullOrWhiteSpace(request.ProductId)
            ? Guid.NewGuid().ToString("N")
            : request.ProductId.Trim();
        var barcode = request.Barcode.Trim();
        if (string.IsNullOrWhiteSpace(barcode))
        {
            barcode = await GenerateBarcode(normalizedMallId);
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new { message = "Product name is required." });
        }

        var existingBarcode = await dbContext.Barcodes.AsNoTracking().FirstOrDefaultAsync(
            x => x.MallId == normalizedMallId && x.Barcode == barcode);
        if (existingBarcode is not null)
        {
            return Conflict(new { message = $"Barcode {barcode} already exists for this mall." });
        }

        var entity = MapToProductEntity(normalizedMallId, productId, request, barcode);
        var barcodeEntity = MapToBarcodeEntity(normalizedMallId, entity);

        dbContext.Products.Add(entity);
        dbContext.Barcodes.Add(barcodeEntity);
        await dbContext.SaveChangesAsync();

        return CreatedAtAction(nameof(GetByBarcode), new { mallId = normalizedMallId, barcode }, ProductDto.FromEntity(entity));
    }

    [HttpPost("bulk-import")]
    public async Task<ActionResult<BulkImportProductsResult>> BulkImport(
        string mallId,
        BulkImportProductsRequest request)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var products = request.Products ?? [];
        if (products.Count == 0)
        {
            return BadRequest(new { message = "At least one product is required for import." });
        }

        var result = new BulkImportProductsResult
        {
            TotalRows = products.Count,
        };
        var seenBarcodesInImport = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var (product, index) in products.Select((value, i) => (value, i)))
        {
            var rowNumber = index + 1;
            try
            {
                var validationError = ValidateImportProduct(product);
                if (validationError is not null)
                {
                    result.Errors.Add($"Row {rowNumber}: {validationError}");
                    result.FailedCount++;
                    continue;
                }

                var barcode = product.Barcode.Trim();
                if (string.IsNullOrWhiteSpace(barcode))
                {
                    barcode = await GenerateBarcode(normalizedMallId);
                }
                else if (!seenBarcodesInImport.Add(barcode))
                {
                    result.Errors.Add($"Row {rowNumber}: Duplicate barcode {barcode} in this upload.");
                    result.FailedCount++;
                    continue;
                }

                var existingBarcode = await dbContext.Barcodes.FirstOrDefaultAsync(
                    x => x.MallId == normalizedMallId && x.Barcode == barcode);

                if (existingBarcode is not null)
                {
                    var existingProduct = await dbContext.Products.FirstOrDefaultAsync(
                        x => x.MallId == normalizedMallId && x.ProductId == existingBarcode.ProductId);

                    if (existingProduct is null)
                    {
                        result.Errors.Add($"Row {rowNumber}: Existing barcode mapping is invalid for {barcode}.");
                        result.FailedCount++;
                        continue;
                    }

                    UpdateProductEntity(existingProduct, product, barcode);
                    UpdateBarcodeEntity(existingBarcode, existingProduct);
                    result.UpdatedCount++;
                    continue;
                }

                var productId = string.IsNullOrWhiteSpace(product.ProductId)
                    ? Guid.NewGuid().ToString("N")
                    : product.ProductId.Trim();
                var entity = MapToProductEntity(normalizedMallId, productId, product, barcode);
                var barcodeEntity = MapToBarcodeEntity(normalizedMallId, entity);

                dbContext.Products.Add(entity);
                dbContext.Barcodes.Add(barcodeEntity);
                result.CreatedCount++;
            }
            catch (Exception ex)
            {
                result.Errors.Add($"Row {rowNumber}: {ex.Message}");
                result.FailedCount++;
            }
        }

        await dbContext.SaveChangesAsync();
        return Ok(result);
    }

    [HttpPut("{productId}")]
    public async Task<ActionResult<ProductDto>> Update(
        string mallId,
        string productId,
        UpsertProductRequest request)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var normalizedProductId = productId.Trim();
        var entity = await dbContext.Products.FirstOrDefaultAsync(
            x => x.MallId == normalizedMallId && x.ProductId == normalizedProductId);
        if (entity is null)
        {
            return NotFound(new { message = "Product not found." });
        }

        var newBarcode = request.Barcode.Trim();
        if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(newBarcode))
        {
            return BadRequest(new { message = "Product name and barcode are required." });
        }

        var barcodeConflict = await dbContext.Barcodes.AsNoTracking().FirstOrDefaultAsync(
            x => x.MallId == normalizedMallId && x.Barcode == newBarcode && x.ProductId != normalizedProductId);
        if (barcodeConflict is not null)
        {
            return Conflict(new { message = $"Barcode {newBarcode} already exists for this mall." });
        }

        var oldBarcode = entity.Barcode;
        entity.Name = request.Name.Trim();
        entity.Barcode = newBarcode;
        entity.ImageUrl = request.ImageUrl.Trim();
        entity.ImageSourcePage = request.ImageSourcePage.Trim();
        entity.Price = request.Price;
        entity.Weight = request.Weight;
        entity.WeightUnit = request.WeightUnit.Trim();
        entity.Unit = request.Unit.Trim();
        entity.Brand = request.Brand.Trim();
        entity.Category = request.Category.Trim();
        entity.Stock = request.Stock;
        entity.InStock = request.InStock;

        var barcodeEntity = await dbContext.Barcodes.FirstOrDefaultAsync(
            x => x.MallId == normalizedMallId && x.ProductId == normalizedProductId);
        if (barcodeEntity is not null)
        {
            if (!string.Equals(oldBarcode, newBarcode, StringComparison.Ordinal))
            {
                dbContext.Barcodes.Remove(barcodeEntity);
                dbContext.Barcodes.Add(MapToBarcodeEntity(normalizedMallId, entity));
            }
            else
            {
                barcodeEntity.ProductName = entity.Name;
                barcodeEntity.ImageUrl = entity.ImageUrl;
                barcodeEntity.ImageSourcePage = entity.ImageSourcePage;
                barcodeEntity.Brand = entity.Brand;
                barcodeEntity.Category = entity.Category;
                barcodeEntity.Price = entity.Price;
                barcodeEntity.Unit = entity.Unit;
                barcodeEntity.InStock = entity.InStock;
                barcodeEntity.UpdatedAt = DateTime.UtcNow;
            }
        }
        else
        {
            dbContext.Barcodes.Add(MapToBarcodeEntity(normalizedMallId, entity));
        }

        await dbContext.SaveChangesAsync();
        return Ok(ProductDto.FromEntity(entity));
    }

    [HttpDelete("{productId}")]
    public async Task<IActionResult> Delete(string mallId, string productId)
    {
        var normalizedMallId = mallId.Trim().ToUpperInvariant();
        if (!CanAccessMall(normalizedMallId))
        {
            return Forbid();
        }

        var normalizedProductId = productId.Trim();
        var entity = await dbContext.Products.FirstOrDefaultAsync(
            x => x.MallId == normalizedMallId && x.ProductId == normalizedProductId);
        if (entity is null)
        {
            return NotFound(new { message = "Product not found." });
        }

        var barcodeEntity = await dbContext.Barcodes.FirstOrDefaultAsync(
            x => x.MallId == normalizedMallId && x.ProductId == normalizedProductId);

        dbContext.Products.Remove(entity);
        if (barcodeEntity is not null)
        {
            dbContext.Barcodes.Remove(barcodeEntity);
        }

        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    private bool CanAccessMall(string mallId)
    {
        if (User.IsInRole("admin") || User.IsInRole("super_admin"))
        {
            return true;
        }

        return string.Equals(
            User.FindFirstValue("mall_id"),
            mallId,
            StringComparison.OrdinalIgnoreCase);
    }

    private async Task<string> GenerateBarcode(string mallId)
    {
        while (true)
        {
            var candidate = $"2{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString()[^11..]}";
            var checkDigit = ComputeEan13CheckDigit(candidate);
            var barcode = $"{candidate}{checkDigit}";
            var exists = await dbContext.Barcodes.AsNoTracking().AnyAsync(
                x => x.MallId == mallId && x.Barcode == barcode);
            if (!exists)
            {
                return barcode;
            }
        }
    }

    private static int ComputeEan13CheckDigit(string base12Digits)
    {
        var sum = 0;
        for (var i = 0; i < base12Digits.Length; i++)
        {
            var digit = int.TryParse(base12Digits[i].ToString(), out var parsed) ? parsed : 0;
            sum += digit * (i % 2 == 0 ? 1 : 3);
        }

        var mod = sum % 10;
        return mod == 0 ? 0 : 10 - mod;
    }

    private static ProductEntity MapToProductEntity(
        string mallId,
        string productId,
        UpsertProductRequest request,
        string barcode)
    {
        return new ProductEntity
        {
            MallId = mallId,
            ProductId = productId,
            Name = request.Name.Trim(),
            Barcode = barcode,
            ImageUrl = request.ImageUrl.Trim(),
            ImageSourcePage = request.ImageSourcePage.Trim(),
            Price = request.Price,
            Weight = request.Weight,
            WeightUnit = request.WeightUnit.Trim(),
            Unit = request.Unit.Trim(),
            Brand = request.Brand.Trim(),
            Category = request.Category.Trim(),
            Stock = request.Stock,
            InStock = request.InStock,
        };
    }

    private static void UpdateProductEntity(
        ProductEntity entity,
        UpsertProductRequest request,
        string barcode)
    {
        entity.Name = request.Name.Trim();
        entity.Barcode = barcode;
        entity.ImageUrl = request.ImageUrl.Trim();
        entity.ImageSourcePage = request.ImageSourcePage.Trim();
        entity.Price = request.Price;
        entity.Weight = request.Weight;
        entity.WeightUnit = request.WeightUnit.Trim();
        entity.Unit = request.Unit.Trim();
        entity.Brand = request.Brand.Trim();
        entity.Category = request.Category.Trim();
        entity.Stock = request.Stock;
        entity.InStock = request.InStock;
    }

    private static BarcodeEntity MapToBarcodeEntity(string mallId, ProductEntity entity)
    {
        return new BarcodeEntity
        {
            MallId = mallId,
            Barcode = entity.Barcode,
            ProductId = entity.ProductId,
            ProductName = entity.Name,
            ImageUrl = entity.ImageUrl,
            ImageSourcePage = entity.ImageSourcePage,
            Brand = entity.Brand,
            Category = entity.Category,
            Price = entity.Price,
            Unit = entity.Unit,
            InStock = entity.InStock,
            UpdatedAt = DateTime.UtcNow,
        };
    }

    private static void UpdateBarcodeEntity(BarcodeEntity entity, ProductEntity product)
    {
        entity.Barcode = product.Barcode;
        entity.ProductId = product.ProductId;
        entity.ProductName = product.Name;
        entity.ImageUrl = product.ImageUrl;
        entity.ImageSourcePage = product.ImageSourcePage;
        entity.Brand = product.Brand;
        entity.Category = product.Category;
        entity.Price = product.Price;
        entity.Unit = product.Unit;
        entity.InStock = product.InStock;
        entity.UpdatedAt = DateTime.UtcNow;
    }

    private static string? ValidateImportProduct(UpsertProductRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return "Product name is required.";
        }

        if (request.Price < 0)
        {
            return "Price cannot be negative.";
        }

        if (request.Stock < 0)
        {
            return "Stock cannot be negative.";
        }

        if (request.Weight < 0)
        {
            return "Weight cannot be negative.";
        }

        return null;
    }
}
