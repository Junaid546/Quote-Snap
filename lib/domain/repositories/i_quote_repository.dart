import '../entities/quote_entity.dart';

abstract class IQuoteRepository {
  Future<List<QuoteEntity>> getQuotes();
  Stream<List<QuoteEntity>> watchQuotes();
  Future<QuoteEntity?> getQuoteById(String id);
  Future<void> createQuote(QuoteEntity quote);
  Future<void> updateQuote(QuoteEntity quote);
  Future<void> deleteQuote(String id);
  Future<void> syncUnsyncedQuotes();
}
