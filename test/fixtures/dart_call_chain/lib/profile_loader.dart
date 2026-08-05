import 'repositories/user_repository.dart';

class ProfileLoader {
  ProfileLoader(this.repository);

  final UserRepository repository;

  Future<Map<String, String>> load() => repository.loadProfile();
}
