namespace SwiftCart.Api.Configuration;

public sealed class MySqlOptions
{
    public const string SectionName = "MySql";

    public string ConnectionString { get; set; } = string.Empty;
    public string ServerVersion { get; set; } = "8.0.36";
}
