using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SwiftCart.Api.Configuration;
using SwiftCart.Api.Data;
using SwiftCart.Api.Services;

var builder = WebApplication.CreateBuilder(args);

var jwtSection = builder.Configuration.GetSection(JwtOptions.SectionName);
var jwtOptions = jwtSection.Get<JwtOptions>() ?? new JwtOptions();
var mySqlSection = builder.Configuration.GetSection(MySqlOptions.SectionName);
var mySqlOptions = mySqlSection.Get<MySqlOptions>() ?? new MySqlOptions();
var setupSection = builder.Configuration.GetSection(SetupOptions.SectionName);
var emailOtpSection = builder.Configuration.GetSection(EmailOtpOptions.SectionName);

builder.Services.Configure<JwtOptions>(
    jwtSection);
builder.Services.Configure<MySqlOptions>(
    mySqlSection);
builder.Services.Configure<SetupOptions>(
    setupSection);
builder.Services.Configure<EmailOtpOptions>(
    emailOtpSection);

builder.Services.AddDbContext<SwiftCartDbContext>(options =>
{
    var version = Version.Parse(mySqlOptions.ServerVersion);
    options.UseMySql(
        mySqlOptions.ConnectionString,
        new MySqlServerVersion(version));
});

builder.Services.AddScoped<PasswordHashService>();
builder.Services.AddScoped<JwtTokenService>();
builder.Services.AddScoped<UserEmailOtpSender>();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi();
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevClient", policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidAudience = jwtOptions.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtOptions.SecretKey)),
            ClockSkew = TimeSpan.Zero,
        };
    });
builder.Services.AddAuthorization();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
app.UseCors("DevClient");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
