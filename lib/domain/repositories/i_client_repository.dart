import '../entities/client_entity.dart';

abstract class IClientRepository {
  Future<List<ClientEntity>> getClients();
  Stream<List<ClientEntity>> watchClients();
  Future<ClientEntity?> getClientById(String id);
  Future<void> createClient(ClientEntity client);
  Future<void> updateClient(ClientEntity client);
  Future<void> deleteClient(String id);
  Future<void> syncUnsyncedClients();
}
