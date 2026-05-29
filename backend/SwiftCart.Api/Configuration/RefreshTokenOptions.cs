namespace SwiftCart.Api.Configuration;

public sealed class RefreshTokenOptions
{
    public const string SectionName = "RefreshToken";

    public int ExpiryMinutes { get; set; } = 120;

    public int MaxActiveTokens { get; set; } = 3;
}
