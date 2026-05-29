using FluentValidation;
using SwiftCart.Api.Models.Managers;

namespace SwiftCart.Api.Configuration.Validators;

public sealed class MallManagerLoginRequestValidator : AbstractValidator<MallManagerLoginRequest>
{
    public MallManagerLoginRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Invalid email format.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.");
    }
}
