using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SwiftCart.Api.Configuration;
using SwiftCart.Api.Data;
using SwiftCart.Api.Services;
using SwiftCart.Api.Configuration.Validators;
using FluentValidation;

var builder = WebApplication.CreateBuilder(args);

var jwtSection = builder.Configuration.GetSection(JwtOptions.SectionName);
var jwtOptions = jwtSection.Get<JwtOptions>() ?? new JwtOptions();
var mySqlSection = builder.Configuration.GetSection(MySqlOptions.SectionName);
var mySqlOptions = mySqlSection.Get<MySqlOptions>() ?? new MySqlOptions();
var setupSection = builder.Configuration.GetSection(SetupOptions.SectionName);
var emailOtpSection = builder.Configuration.GetSection(EmailOtpOptions.SectionName);
var refreshTokenSection = builder.Configuration.GetSection(RefreshTokenOptions.SectionName);

builder.Services.Configure<JwtOptions>(
    jwtSection);
builder.Services.Configure<MySqlOptions>(
    mySqlSection);
builder.Services.Configure<SetupOptions>(
    setupSection);
builder.Services.Configure<EmailOtpOptions>(
    emailOtpSection);
builder.Services.Configure<RefreshTokenOptions>(
    refreshTokenSection);

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
builder.Services.AddScoped<RefreshTokenService>();

builder.Services.AddScoped<IValidator<AdminLoginRequest>, AdminLoginRequestValidator>();
builder.Services.AddScoped<IValidator<MallManagerLoginRequest>, MallManagerLoginRequestValidator>();
builder.Services.AddScoped<IValidator<UserLoginRequest>, UserLoginRequestValidator>();
builder.Services.AddScoped<IValidator<RefreshTokenRequest>, RefreshTokenRequestValidator>();
builder.Services.AddScoped<IValidator<MySqlOptions>, MySqlOptionsValidator>();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi();
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddFluentValidationClientsideAdapters();
builder.Services.AddCors(options =>
{
    options.AddPolicy("SwiftCartCors", policy =>
    {
        policy.WithOrigins(
                "http://localhost:5187", 
                "http://localhost:3000", 
                "https://aditya10507.github.io",
                "https://Aditya10507.github.io")
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
app.UseCors("SwiftCartCors");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapAuthenticationEndpoints();

app.Run();
