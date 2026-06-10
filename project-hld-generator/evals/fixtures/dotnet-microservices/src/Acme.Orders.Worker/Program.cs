using Acme.Orders.Worker;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddHostedService<OrderEventsConsumer>();
builder.Build().Run();
