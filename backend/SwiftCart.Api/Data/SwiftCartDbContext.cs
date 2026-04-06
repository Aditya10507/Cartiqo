using Microsoft.EntityFrameworkCore;
using SwiftCart.Api.Models.Entities;

namespace SwiftCart.Api.Data;

public sealed class SwiftCartDbContext(DbContextOptions<SwiftCartDbContext> options)
    : DbContext(options)
{
    public DbSet<AdminEntity> Admins => Set<AdminEntity>();
    public DbSet<MallEntity> Malls => Set<MallEntity>();
    public DbSet<MallManagerEntity> MallManagers => Set<MallManagerEntity>();
    public DbSet<MallManagerEmailOtpEntity> MallManagerEmailOtps => Set<MallManagerEmailOtpEntity>();
    public DbSet<UserProfileEntity> UserProfiles => Set<UserProfileEntity>();
    public DbSet<UserEmailOtpEntity> UserEmailOtps => Set<UserEmailOtpEntity>();
    public DbSet<UserPasswordResetOtpEntity> UserPasswordResetOtps => Set<UserPasswordResetOtpEntity>();
    public DbSet<ProductEntity> Products => Set<ProductEntity>();
    public DbSet<BarcodeEntity> Barcodes => Set<BarcodeEntity>();
    public DbSet<BillEntity> Bills => Set<BillEntity>();
    public DbSet<PaymentEntity> Payments => Set<PaymentEntity>();
    public DbSet<AnnouncementEntity> Announcements => Set<AnnouncementEntity>();
    public DbSet<SupportRequestEntity> SupportRequests => Set<SupportRequestEntity>();
    public DbSet<PromotionEntity> Promotions => Set<PromotionEntity>();
    public DbSet<StaffActivityEntity> StaffActivities => Set<StaffActivityEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<AdminEntity>(entity =>
        {
            entity.ToTable("admins");
            entity.HasKey(x => x.Id);

            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Name).HasColumnName("name").HasMaxLength(120);
            entity.Property(x => x.Email).HasColumnName("email").HasMaxLength(160);
            entity.Property(x => x.PasswordHash)
                .HasColumnName("password_hash")
                .HasMaxLength(128);
            entity.Property(x => x.Role).HasColumnName("role").HasMaxLength(50);
            entity.Property(x => x.IsActive).HasColumnName("is_active");
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");

            entity.HasIndex(x => x.Email).IsUnique();
        });

        modelBuilder.Entity<MallEntity>(entity =>
        {
            entity.ToTable("malls");
            entity.HasKey(x => x.MallId);

            entity.Property(x => x.MallId)
                .HasColumnName("mall_id")
                .HasMaxLength(20);
            entity.Property(x => x.Name).HasColumnName("name").HasMaxLength(160);
            entity.Property(x => x.OwnerName)
                .HasColumnName("owner_name")
                .HasMaxLength(160);
            entity.Property(x => x.OwnerEmail)
                .HasColumnName("owner_email")
                .HasMaxLength(160);
            entity.Property(x => x.City).HasColumnName("city").HasMaxLength(120);
            entity.Property(x => x.State).HasColumnName("state").HasMaxLength(120);
            entity.Property(x => x.SubscriptionStartDate)
                .HasColumnName("subscription_start_date");
            entity.Property(x => x.SubscriptionEndDate)
                .HasColumnName("subscription_end_date");
            entity.Property(x => x.PlanType)
                .HasColumnName("plan_type")
                .HasMaxLength(50);
            entity.Property(x => x.MaxProducts).HasColumnName("max_products");
            entity.Property(x => x.IsActive).HasColumnName("is_active");
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");
            entity.Property(x => x.AreaCode)
                .HasColumnName("area_code")
                .HasMaxLength(20);
            entity.Property(x => x.EstYear).HasColumnName("est_year");
            entity.Property(x => x.MallCode)
                .HasColumnName("mall_code")
                .HasMaxLength(20);
            entity.Property(x => x.MallNumber).HasColumnName("mall_number");
            entity.Property(x => x.Active).HasColumnName("active");
            entity.Property(x => x.GstPercent)
                .HasColumnName("gst_percent")
                .HasPrecision(8, 2);
            entity.Property(x => x.TaxLabel)
                .HasColumnName("tax_label")
                .HasMaxLength(100);
            entity.Property(x => x.TaxPercent)
                .HasColumnName("tax_percent")
                .HasPrecision(8, 2);
            entity.Property(x => x.ExtraChargeLabel)
                .HasColumnName("extra_charge_label")
                .HasMaxLength(100);
            entity.Property(x => x.ExtraChargeAmount)
                .HasColumnName("extra_charge_amount")
                .HasPrecision(12, 2);
        });

        modelBuilder.Entity<MallManagerEntity>(entity =>
        {
            entity.ToTable("mall_managers");
            entity.HasKey(x => x.ManagerId);

            entity.Property(x => x.ManagerId)
                .HasColumnName("manager_id")
                .HasMaxLength(40);
            entity.Property(x => x.MallId)
                .HasColumnName("mall_id")
                .HasMaxLength(20);
            entity.Property(x => x.AssignedUid)
                .HasColumnName("assigned_uid")
                .HasMaxLength(128);
            entity.Property(x => x.AssignedEmail)
                .HasColumnName("assigned_email")
                .HasMaxLength(160);
            entity.Property(x => x.IsActive).HasColumnName("is_active");
            entity.Property(x => x.PasswordHash)
                .HasColumnName("password_hash")
                .HasMaxLength(128);
            entity.Property(x => x.PasswordUpdatedAt)
                .HasColumnName("password_updated_at");
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");
            entity.Property(x => x.UpdatedAt).HasColumnName("updated_at");
            entity.Property(x => x.LinkedAt).HasColumnName("linked_at");
            entity.Property(x => x.FullName)
                .HasColumnName("full_name")
                .HasMaxLength(160);
            entity.Property(x => x.PhoneNumber)
                .HasColumnName("phone_number")
                .HasMaxLength(40);
            entity.Property(x => x.DateOfJoining)
                .HasColumnName("date_of_joining");
            entity.Property(x => x.LastLoginAt)
                .HasColumnName("last_login_at");

            entity.HasIndex(x => x.MallId);
        });

        modelBuilder.Entity<MallManagerEmailOtpEntity>(entity =>
        {
            entity.ToTable("mall_manager_email_otps");
            entity.HasKey(x => x.Email);

            entity.Property(x => x.Email)
                .HasColumnName("email")
                .HasMaxLength(160);
            entity.Property(x => x.ManagerId)
                .HasColumnName("manager_id")
                .HasMaxLength(40);
            entity.Property(x => x.OtpCode)
                .HasColumnName("otp_code")
                .HasMaxLength(16);
            entity.Property(x => x.Attempts)
                .HasColumnName("attempts");
            entity.Property(x => x.ExpiresAtUtc)
                .HasColumnName("expires_at_utc");
            entity.Property(x => x.CreatedAtUtc)
                .HasColumnName("created_at_utc");
            entity.Property(x => x.UpdatedAtUtc)
                .HasColumnName("updated_at_utc");
        });

        modelBuilder.Entity<UserProfileEntity>(entity =>
        {
            entity.ToTable("users");
            entity.HasKey(x => x.Uid);

            entity.Property(x => x.Uid)
                .HasColumnName("uid")
                .HasMaxLength(128);
            entity.Property(x => x.Username)
                .HasColumnName("username")
                .HasMaxLength(60);
            entity.Property(x => x.PasswordHash)
                .HasColumnName("password_hash")
                .HasMaxLength(128);
            entity.Property(x => x.FullName)
                .HasColumnName("full_name")
                .HasMaxLength(160);
            entity.Property(x => x.DisplayName)
                .HasColumnName("display_name")
                .HasMaxLength(160);
            entity.Property(x => x.Email)
                .HasColumnName("email")
                .HasMaxLength(160);
            entity.Property(x => x.Phone)
                .HasColumnName("phone")
                .HasMaxLength(40);
            entity.Property(x => x.PhotoUrl)
                .HasColumnName("photo_url")
                .HasMaxLength(512);
            entity.Property(x => x.LocalPhotoPath)
                .HasColumnName("local_photo_path")
                .HasMaxLength(512);
            entity.Property(x => x.AvatarPreset)
                .HasColumnName("avatar_preset")
                .HasMaxLength(40);
            entity.Property(x => x.Provider)
                .HasColumnName("provider")
                .HasMaxLength(40);
            entity.Property(x => x.EmailVerified)
                .HasColumnName("email_verified");
            entity.Property(x => x.LastLoginAt)
                .HasColumnName("last_login_at");
            entity.Property(x => x.CreatedAt)
                .HasColumnName("created_at");
            entity.Property(x => x.UpdatedAt)
                .HasColumnName("updated_at");

            entity.HasIndex(x => x.Email);
            entity.HasIndex(x => x.Username).IsUnique();
            entity.HasIndex(x => x.Phone);
        });

        modelBuilder.Entity<UserEmailOtpEntity>(entity =>
        {
            entity.ToTable("user_email_otps");
            entity.HasKey(x => x.Email);

            entity.Property(x => x.Email)
                .HasColumnName("email")
                .HasMaxLength(160);
            entity.Property(x => x.FirstName)
                .HasColumnName("first_name")
                .HasMaxLength(100);
            entity.Property(x => x.LastName)
                .HasColumnName("last_name")
                .HasMaxLength(100);
            entity.Property(x => x.Username)
                .HasColumnName("username")
                .HasMaxLength(60);
            entity.Property(x => x.FullName)
                .HasColumnName("full_name")
                .HasMaxLength(160);
            entity.Property(x => x.PasswordHash)
                .HasColumnName("password_hash")
                .HasMaxLength(128);
            entity.Property(x => x.OtpCode)
                .HasColumnName("otp_code")
                .HasMaxLength(16);
            entity.Property(x => x.Attempts)
                .HasColumnName("attempts");
            entity.Property(x => x.ExpiresAtUtc)
                .HasColumnName("expires_at_utc");
            entity.Property(x => x.CreatedAtUtc)
                .HasColumnName("created_at_utc");
            entity.Property(x => x.UpdatedAtUtc)
                .HasColumnName("updated_at_utc");
        });

        modelBuilder.Entity<UserPasswordResetOtpEntity>(entity =>
        {
            entity.ToTable("user_password_reset_otps");
            entity.HasKey(x => x.Email);

            entity.Property(x => x.Email)
                .HasColumnName("email")
                .HasMaxLength(160);
            entity.Property(x => x.OtpCode)
                .HasColumnName("otp_code")
                .HasMaxLength(16);
            entity.Property(x => x.Attempts)
                .HasColumnName("attempts");
            entity.Property(x => x.ExpiresAtUtc)
                .HasColumnName("expires_at_utc");
            entity.Property(x => x.CreatedAtUtc)
                .HasColumnName("created_at_utc");
            entity.Property(x => x.UpdatedAtUtc)
                .HasColumnName("updated_at_utc");
        });

        modelBuilder.Entity<ProductEntity>(entity =>
        {
            entity.ToTable("products");
            entity.HasKey(x => x.ProductId);

            entity.Property(x => x.ProductId)
                .HasColumnName("product_id")
                .HasMaxLength(128);
            entity.Property(x => x.MallId)
                .HasColumnName("mall_id")
                .HasMaxLength(20);
            entity.Property(x => x.Name)
                .HasColumnName("name")
                .HasMaxLength(200);
            entity.Property(x => x.Barcode)
                .HasColumnName("barcode")
                .HasMaxLength(64);
            entity.Property(x => x.ImageUrl)
                .HasColumnName("image_url")
                .HasMaxLength(512);
            entity.Property(x => x.ImageSourcePage)
                .HasColumnName("image_source_page")
                .HasMaxLength(512);
            entity.Property(x => x.Price)
                .HasColumnName("price")
                .HasPrecision(18, 2);
            entity.Property(x => x.Weight)
                .HasColumnName("weight")
                .HasPrecision(18, 3);
            entity.Property(x => x.WeightUnit)
                .HasColumnName("weight_unit")
                .HasMaxLength(16);
            entity.Property(x => x.Unit)
                .HasColumnName("unit")
                .HasMaxLength(40);
            entity.Property(x => x.Brand)
                .HasColumnName("brand")
                .HasMaxLength(120);
            entity.Property(x => x.Category)
                .HasColumnName("category")
                .HasMaxLength(120);
            entity.Property(x => x.Stock).HasColumnName("stock");
            entity.Property(x => x.InStock).HasColumnName("in_stock");

            entity.HasIndex(x => x.MallId);
            entity.HasIndex(x => new { x.MallId, x.Barcode });
        });

        modelBuilder.Entity<BarcodeEntity>(entity =>
        {
            entity.ToTable("barcodes");
            entity.HasKey(x => x.Barcode);

            entity.Property(x => x.Barcode)
                .HasColumnName("barcode")
                .HasMaxLength(64);
            entity.Property(x => x.MallId)
                .HasColumnName("mall_id")
                .HasMaxLength(20);
            entity.Property(x => x.ProductId)
                .HasColumnName("product_id")
                .HasMaxLength(128);
            entity.Property(x => x.ProductName)
                .HasColumnName("product_name")
                .HasMaxLength(200);
            entity.Property(x => x.ImageUrl)
                .HasColumnName("image_url")
                .HasMaxLength(512);
            entity.Property(x => x.ImageSourcePage)
                .HasColumnName("image_source_page")
                .HasMaxLength(512);
            entity.Property(x => x.Brand)
                .HasColumnName("brand")
                .HasMaxLength(120);
            entity.Property(x => x.Category)
                .HasColumnName("category")
                .HasMaxLength(120);
            entity.Property(x => x.Price)
                .HasColumnName("price")
                .HasPrecision(18, 2);
            entity.Property(x => x.Unit)
                .HasColumnName("unit")
                .HasMaxLength(40);
            entity.Property(x => x.InStock).HasColumnName("in_stock");
            entity.Property(x => x.UpdatedAt).HasColumnName("updated_at");

            entity.HasIndex(x => x.MallId);
            entity.HasIndex(x => x.ProductId);
        });

        modelBuilder.Entity<BillEntity>(entity =>
        {
            entity.ToTable("bills");
            entity.HasKey(x => x.BillId);

            entity.Property(x => x.BillId).HasColumnName("bill_id").HasMaxLength(128);
            entity.Property(x => x.BillNumber).HasColumnName("bill_number").HasMaxLength(128);
            entity.Property(x => x.MallId).HasColumnName("mall_id").HasMaxLength(20);
            entity.Property(x => x.UserId).HasColumnName("user_id").HasMaxLength(128);
            entity.Property(x => x.CustomerName).HasColumnName("customer_name").HasMaxLength(200);
            entity.Property(x => x.CustomerEmail).HasColumnName("customer_email").HasMaxLength(160);
            entity.Property(x => x.CustomerPhone).HasColumnName("customer_phone").HasMaxLength(40);
            entity.Property(x => x.Subtotal).HasColumnName("subtotal");
            entity.Property(x => x.ExtraCharge).HasColumnName("extra_charge");
            entity.Property(x => x.ExtraChargeLabel).HasColumnName("extra_charge_label").HasMaxLength(100);
            entity.Property(x => x.Gst).HasColumnName("gst");
            entity.Property(x => x.GstPercent).HasColumnName("gst_percent").HasPrecision(8, 2);
            entity.Property(x => x.OtherTax).HasColumnName("other_tax");
            entity.Property(x => x.OtherTaxLabel).HasColumnName("other_tax_label").HasMaxLength(100);
            entity.Property(x => x.OtherTaxPercent).HasColumnName("other_tax_percent").HasPrecision(8, 2);
            entity.Property(x => x.Total).HasColumnName("total");
            entity.Property(x => x.ItemCount).HasColumnName("item_count");
            entity.Property(x => x.ItemsJson).HasColumnName("items_json").HasColumnType("longtext");
            entity.Property(x => x.Status).HasColumnName("status").HasMaxLength(40);
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");

            entity.HasIndex(x => x.MallId);
            entity.HasIndex(x => x.UserId);
            entity.HasIndex(x => x.BillNumber);
        });

        modelBuilder.Entity<PaymentEntity>(entity =>
        {
            entity.ToTable("payments");
            entity.HasKey(x => x.PaymentId);

            entity.Property(x => x.PaymentId).HasColumnName("payment_id").HasMaxLength(128);
            entity.Property(x => x.PaymentNumber).HasColumnName("payment_number").HasMaxLength(128);
            entity.Property(x => x.BillId).HasColumnName("bill_id").HasMaxLength(128);
            entity.Property(x => x.BillNumber).HasColumnName("bill_number").HasMaxLength(128);
            entity.Property(x => x.MallId).HasColumnName("mall_id").HasMaxLength(20);
            entity.Property(x => x.UserId).HasColumnName("user_id").HasMaxLength(128);
            entity.Property(x => x.CustomerName).HasColumnName("customer_name").HasMaxLength(200);
            entity.Property(x => x.CustomerEmail).HasColumnName("customer_email").HasMaxLength(160);
            entity.Property(x => x.CustomerPhone).HasColumnName("customer_phone").HasMaxLength(40);
            entity.Property(x => x.Amount).HasColumnName("amount");
            entity.Property(x => x.Subtotal).HasColumnName("subtotal");
            entity.Property(x => x.ExtraCharge).HasColumnName("extra_charge");
            entity.Property(x => x.ExtraChargeLabel).HasColumnName("extra_charge_label").HasMaxLength(100);
            entity.Property(x => x.Gst).HasColumnName("gst");
            entity.Property(x => x.GstPercent).HasColumnName("gst_percent").HasPrecision(8, 2);
            entity.Property(x => x.OtherTax).HasColumnName("other_tax");
            entity.Property(x => x.OtherTaxLabel).HasColumnName("other_tax_label").HasMaxLength(100);
            entity.Property(x => x.OtherTaxPercent).HasColumnName("other_tax_percent").HasPrecision(8, 2);
            entity.Property(x => x.Method).HasColumnName("method").HasMaxLength(40);
            entity.Property(x => x.Reference).HasColumnName("reference").HasMaxLength(160);
            entity.Property(x => x.Status).HasColumnName("status").HasMaxLength(40);
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");

            entity.HasIndex(x => x.MallId);
            entity.HasIndex(x => x.UserId);
            entity.HasIndex(x => x.BillId);
            entity.HasIndex(x => x.PaymentNumber);
        });

        modelBuilder.Entity<AnnouncementEntity>(entity =>
        {
            entity.ToTable("announcements");
            entity.HasKey(x => x.Id);

            entity.Property(x => x.Id).HasColumnName("id").HasMaxLength(64);
            entity.Property(x => x.Title).HasColumnName("title").HasMaxLength(200);
            entity.Property(x => x.Message).HasColumnName("message").HasColumnType("longtext");
            entity.Property(x => x.Audience).HasColumnName("audience").HasMaxLength(40);
            entity.Property(x => x.CreatedBy).HasColumnName("created_by").HasMaxLength(160);
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");
        });

        modelBuilder.Entity<SupportRequestEntity>(entity =>
        {
            entity.ToTable("support_requests");
            entity.HasKey(x => x.Id);

            entity.Property(x => x.Id).HasColumnName("id").HasMaxLength(64);
            entity.Property(x => x.Type).HasColumnName("type").HasMaxLength(40);
            entity.Property(x => x.Name).HasColumnName("name").HasMaxLength(160);
            entity.Property(x => x.Email).HasColumnName("email").HasMaxLength(160);
            entity.Property(x => x.Message).HasColumnName("message").HasColumnType("longtext");
            entity.Property(x => x.Status).HasColumnName("status").HasMaxLength(40);
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");
            entity.Property(x => x.UpdatedAt).HasColumnName("updated_at");

            entity.HasIndex(x => x.Status);
            entity.HasIndex(x => x.Email);
        });

        modelBuilder.Entity<PromotionEntity>(entity =>
        {
            entity.ToTable("promotions");
            entity.HasKey(x => x.Id);

            entity.Property(x => x.Id).HasColumnName("id").HasMaxLength(64);
            entity.Property(x => x.MallId).HasColumnName("mall_id").HasMaxLength(20);
            entity.Property(x => x.Title).HasColumnName("title").HasMaxLength(200);
            entity.Property(x => x.Description).HasColumnName("description").HasColumnType("longtext");
            entity.Property(x => x.DiscountLabel).HasColumnName("discount_label").HasMaxLength(120);
            entity.Property(x => x.StartDate).HasColumnName("start_date");
            entity.Property(x => x.EndDate).HasColumnName("end_date");
            entity.Property(x => x.IsActive).HasColumnName("is_active");
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");
            entity.Property(x => x.UpdatedAt).HasColumnName("updated_at");

            entity.HasIndex(x => x.MallId);
        });

        modelBuilder.Entity<StaffActivityEntity>(entity =>
        {
            entity.ToTable("staff_activity");
            entity.HasKey(x => x.Id);

            entity.Property(x => x.Id).HasColumnName("id").HasMaxLength(64);
            entity.Property(x => x.MallId).HasColumnName("mall_id").HasMaxLength(20);
            entity.Property(x => x.Action).HasColumnName("action").HasMaxLength(160);
            entity.Property(x => x.Details).HasColumnName("details").HasColumnType("longtext");
            entity.Property(x => x.ManagerId).HasColumnName("manager_id").HasMaxLength(40);
            entity.Property(x => x.ManagerEmail).HasColumnName("manager_email").HasMaxLength(160);
            entity.Property(x => x.CreatedAt).HasColumnName("created_at");

            entity.HasIndex(x => x.MallId);
        });
    }
}
