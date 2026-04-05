using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SwiftCart.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddMallManagerProfileAndBillingSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "extra_charge_amount",
                table: "malls",
                type: "decimal(12,2)",
                precision: 12,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "extra_charge_label",
                table: "malls",
                type: "varchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<decimal>(
                name: "gst_percent",
                table: "malls",
                type: "decimal(8,2)",
                precision: 8,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "tax_label",
                table: "malls",
                type: "varchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<decimal>(
                name: "tax_percent",
                table: "malls",
                type: "decimal(8,2)",
                precision: 8,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<DateTime>(
                name: "date_of_joining",
                table: "mall_managers",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "full_name",
                table: "mall_managers",
                type: "varchar(160)",
                maxLength: 160,
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<DateTime>(
                name: "last_login_at",
                table: "mall_managers",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "phone_number",
                table: "mall_managers",
                type: "varchar(40)",
                maxLength: 40,
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "extra_charge_amount",
                table: "malls");

            migrationBuilder.DropColumn(
                name: "extra_charge_label",
                table: "malls");

            migrationBuilder.DropColumn(
                name: "gst_percent",
                table: "malls");

            migrationBuilder.DropColumn(
                name: "tax_label",
                table: "malls");

            migrationBuilder.DropColumn(
                name: "tax_percent",
                table: "malls");

            migrationBuilder.DropColumn(
                name: "date_of_joining",
                table: "mall_managers");

            migrationBuilder.DropColumn(
                name: "full_name",
                table: "mall_managers");

            migrationBuilder.DropColumn(
                name: "last_login_at",
                table: "mall_managers");

            migrationBuilder.DropColumn(
                name: "phone_number",
                table: "mall_managers");
        }
    }
}
