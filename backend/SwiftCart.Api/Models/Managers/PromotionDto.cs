using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Models.Managers;

public sealed class PromotionDto
{
    public string Id { get; set; } = string.Empty;
    public string MallId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string DiscountLabel { get; set; } = string.Empty;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public static PromotionDto FromEntity(PromotionEntity entity)
    {
        return new PromotionDto
        {
            Id = entity.Id,
            MallId = entity.MallId,
            Title = entity.Title,
            Description = entity.Description,
            DiscountLabel = entity.DiscountLabel,
            StartDate = entity.StartDate,
            EndDate = entity.EndDate,
            IsActive = entity.IsActive,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt,
        };
    }
}
