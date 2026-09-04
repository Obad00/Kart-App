import '../../../core/network/api_client.dart';
import '../models/company_job.dart';
import '../models/discoverable_company.dart';

/// "Entreprises à découvrir" — cf. CompanyDiscoveryController côté backend.
class CompanyDiscoveryService {
  Future<List<DiscoverableCompany>> fetchCompanies() async {
    final response = await ApiClient.dio.get('/companies/discover');
    return (response.data['data'] as List)
        .map((e) => DiscoverableCompany.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CompanyDetail> fetchCompanyDetail(int companyId) async {
    final response = await ApiClient.dio.get('/companies/discover/$companyId');
    return CompanyDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> follow(int companyId) async {
    await ApiClient.dio.post('/companies/$companyId/follow');
  }

  Future<void> unfollow(int companyId) async {
    await ApiClient.dio.delete('/companies/$companyId/follow');
  }
}
