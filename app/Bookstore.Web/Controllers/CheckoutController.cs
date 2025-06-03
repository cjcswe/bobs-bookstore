using Bookstore.Domain.Addresses;
using Bookstore.Domain.Carts;
using Bookstore.Domain.Orders;
using Bookstore.Web.Helpers;
using Bookstore.Web.ViewModel.Checkout;
using System.Web.Mvc;
using System.Threading.Tasks;
using Bookstore.Data.Carts;
using Bookstore.Data.Orders;
using Bookstore.Data;

namespace Bookstore.Web.Controllers
{
    public class CheckoutController : Controller
    {
        private readonly IAddressService addressService;
        private readonly IShoppingCartService shoppingCartService;
        private readonly IOrderService orderService;

        public CheckoutController()
        {
            this.shoppingCartService = InstanceCreator.GetShoppingCartService();
            this.orderService = InstanceCreator.GetOrderService();
            this.addressService = InstanceCreator.GetAddressService();
        }

        public async Task<ActionResult> Index()
        {
            var shoppingCart = await shoppingCartService.GetShoppingCartAsync(HttpContext.GetShoppingCartCorrelationId());
            var addresses = await addressService.GetAddressesAsync(User.GetSub());

            return View(new CheckoutIndexViewModel(shoppingCart, addresses));
        }

        [HttpPost]
        public async Task<ActionResult> Index(CheckoutIndexViewModel model)
        {
            if(!ModelState.IsValid) return  View(model);

            var dto = new CreateOrderDto(User.GetSub(), HttpContext.GetShoppingCartCorrelationId(), model.SelectedAddressId);

            var orderId = await orderService.CreateOrderAsync(dto);

            return RedirectToAction("Finished", new { orderId });
        }

        public async Task<ActionResult> Finished(int orderId)
        {
            var order = await orderService.GetOrderAsync(orderId);

            return View(new CheckoutFinishedViewModel(order));
        }
    }
}
