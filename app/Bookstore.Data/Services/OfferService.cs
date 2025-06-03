using Bookstore.Domain;
using Bookstore.Domain.Customers;
using Bookstore.Domain.Offers;
using Bookstore.Domain.Orders;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Bookstore.Data.Offers
{
    public interface IOfferService
    {
        Task<IPaginatedList<Offer>> GetOffersAsync(OfferFilters filters, int pageIndex, int pageSize);

        Task<IEnumerable<Offer>> GetOffersAsync(string sub);

        Task<Offer> GetOfferAsync(int offerId);

        Task CreateOfferAsync(CreateOfferDto createOfferDto);

        Task UpdateOfferStatusAsync(UpdateOfferStatusDto updateOfferStatusDto);

        Task<OfferStatistics> GetStatisticsAsync();
    }

    public class OfferService : IOfferService
    {
        private readonly IOfferRepository offerRepository;
        private readonly ICustomerRepository customerRepository;

        public OfferService()
        {
            this.offerRepository = InstanceCreator.GetOfferRepository();
            this.customerRepository = InstanceCreator.GetCustomerRepository();
        }

        public async Task<IPaginatedList<Offer>> GetOffersAsync(OfferFilters filters, int pageIndex, int pageSize)
        {
            return await offerRepository.ListAsync(filters, pageIndex, pageSize);
        }

        public async Task<IEnumerable<Offer>> GetOffersAsync(string sub)
        {
            return await offerRepository.ListAsync(sub);
        }

        public async Task<Offer> GetOfferAsync(int id)
        {
            return await offerRepository.GetAsync(id);
        }

        public async Task CreateOfferAsync(CreateOfferDto dto)
        {
            var customer = await customerRepository.GetAsync(dto.CustomerSub);

            var offer = new Offer(
                customer.Id,
                dto.BookName,
                dto.Author,
                dto.ISBN,
                dto.BookTypeId,
                dto.ConditionId,
                dto.GenreId,
                dto.PublisherId,
                dto.BookPrice);

            await offerRepository.AddAsync(offer);

            await offerRepository.SaveChangesAsync();
        }

        public async Task UpdateOfferStatusAsync(UpdateOfferStatusDto dto)
        {
            var offer = await GetOfferAsync(dto.OfferId);

            offer.OfferStatus = dto.Status;

            offer.UpdatedOn = DateTime.UtcNow;

            await offerRepository.SaveChangesAsync();
        }

        public async Task<OfferStatistics> GetStatisticsAsync()
        {
            return (await offerRepository.GetStatisticsAsync()) ?? new OfferStatistics();
        }
    }
}