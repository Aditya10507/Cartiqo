namespace SwiftCart.Api.Configuration;

public sealed class SetupOptions
{
    public const string SectionName = "Setup";

    public bool EnableBootstrapEndpoints { get; set; } = true;
    public string BootstrapKey { get; set; } = "CHANGE_THIS_SETUP_KEY";
}
