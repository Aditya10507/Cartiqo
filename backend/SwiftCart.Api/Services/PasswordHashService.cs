using Microsoft.AspNetCore.Identity;

namespace SwiftCart.Api.Services;

public sealed class PasswordHashService
{
    private readonly PasswordHasher<object> _hasher = new();

    public string HashPassword(string password) => _hasher.HashPassword(new object(), password);

    public bool VerifyPassword(string password, string hashedPassword)
    {
        return _hasher.VerifyHashedPassword(new object(), hashedPassword, password) != PasswordVerificationResult.Failed;
    }
}
