namespace Acme.Orders.Domain;

public class Order
{
    public Guid Id { get; private set; }
    public Guid CustomerId { get; private set; }
    public List<OrderLine> Lines { get; } = new();
    public OrderStatus Status { get; private set; }
}

public record OrderLine(string Sku, int Quantity, decimal UnitPrice);
public enum OrderStatus { Pending, Confirmed, Shipped, Cancelled }
