/// Service Locator for Dependency Injection
/// This is a simple implementation without external DI packages
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  
  factory ServiceLocator() => _instance;
  
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};

  /// Register a singleton instance
  void registerSingleton<T>(T instance) {
    _services[T] = instance;
  }

  /// Register a factory function
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Get a registered service
  T get<T>() {
    // Check if singleton exists
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    // Check if factory exists
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw Exception('Service of type $T is not registered');
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Reset all services (useful for testing)
  void reset() {
    _services.clear();
    _factories.clear();
  }
}