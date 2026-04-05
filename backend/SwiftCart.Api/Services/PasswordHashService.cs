using System.Security.Cryptography;
using System.Text;

namespace SwiftCart.Api.Services;

public sealed class PasswordHashService
{
    public string ComputeSha256(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
