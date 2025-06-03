using BobsBookstoreClassic.Data;
using Bookstore.Data;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Bookstore.Domain
{
    public class ServiceProvider
    {
        public static ApplicationDbContext GetApplicationDbContext()
        {
            return new ApplicationDbContext(BookstoreConfiguration.Get("ConnectionStrings/BookstoreDatabaseConnection"));
        }
    }
}