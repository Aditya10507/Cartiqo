using Microsoft.AspNetCore.Mvc;

namespace SwiftCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            status = "ok",
            service = "SwiftCart.Api",
            utcTime = DateTime.UtcNow,
        });
    }
}
