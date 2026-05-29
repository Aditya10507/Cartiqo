using FluentValidation;

namespace SwiftCart.Api.Configuration.Validators;

public sealed class MySqlOptionsValidator : AbstractValidator<MySqlOptions>
{
    public MySqlOptionsValidator()
    {
        RuleFor(x => x.ConnectionString).NotEmpty()
            .WithMessage("MySqlOptions:ConnectionString cannot be empty");
    }
}
