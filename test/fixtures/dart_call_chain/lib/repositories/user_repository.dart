import '../services/user_service.dart';

class UserRepository {
  UserRepository(this.service);

  final UserService service;

  Future<Map<String, String>> loadProfile() {
    return service.fetchProfile();
  }
}
