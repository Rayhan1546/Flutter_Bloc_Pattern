import 'package:junie_ai_test/di/di_module.dart';

/// Registers all dependency injection modules
///
/// Modules are registered in order:
/// 1. NetworkModule - Core network dependencies (Dio)
/// 2. DataModule - Data sources and repositories
/// 3. DomainModule - Use cases
/// 4. PresentationModule - Cubits/Blocs
Future<void> registerModules() async {
  final modules = <DIModule>[
    NetworkModule(),
    DataModule(),
    DomainModule(),
    PresentationModule(),
  ];

  for (final module in modules) {
    await module.register();
  }
}
