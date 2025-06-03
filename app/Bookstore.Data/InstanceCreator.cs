using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Bookstore.Data.Books;
using Bookstore.Data.Carts;
using Bookstore.Data.Customers;
using Bookstore.Data.ImageResizeService;
using Bookstore.Data.Offers;
using Bookstore.Data.Orders;
using Bookstore.Data.ReferenceData;
using Bookstore.Data.Repositories;
using Bookstore.Domain.Addresses;
using Bookstore.Domain.Carts;
using Bookstore.Domain.Customers;
using Bookstore.Domain.Offers;
using Bookstore.Domain.ReferenceData;

namespace Bookstore.Data
{
    public class InstanceCreator
    {
        public static ImageResizeService.ImageResizeService GetImageResizeService() => new Bookstore.Data.ImageResizeService.ImageResizeService();
        public static ImageValidationServices.LocalImageValidationService GetLocalImageValidationService() => new ImageValidationServices.LocalImageValidationService();
        public static FileServices.LocalFileService GetLocalFileService() => new FileServices.LocalFileService();
        public static BookRepository GetBookRepository() => new BookRepository();
        public static OrderRepository GetOrderRepository() => new OrderRepository();

        public static BookService GetBookService() => new BookService();

        public static IAddressService GetAddressService() => new AddressService();

        public static ICustomerService GetCustomerService() => new CustomerService();
        public static IShoppingCartService GetShoppingCartService() => new ShoppingCartService();

        public static IOrderService GetOrderService() => new OrderService();

        public static IReferenceDataService GetReferenceDataService() => new ReferenceDataService();

        public static IOfferService GetOfferService() => new OfferService();

        internal static IAddressRepository GetAddressRepository() => new AddressRepository();

        internal static ICustomerRepository GetCustomerRepository() => new CustomerRepository();

        internal static IShoppingCartRepository GetShoppingCartRepository() => new ShoppingCartRepository();

        internal static IReferenceDataRepository GetReferenceDataRepository() => new ReferenceDataRepository();

        internal static IOfferRepository GetOfferRepository() => new OfferRepository(); 
    }
}
