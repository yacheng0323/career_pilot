// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiClientHash() => r'cdc65f44d0ec7d7c3a88a5d035707e0245b00546';

/// See also [apiClient].
@ProviderFor(apiClient)
final apiClientProvider = Provider<ApiClient>.internal(
  apiClient,
  name: r'apiClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$apiClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApiClientRef = ProviderRef<ApiClient>;
String _$jobListHash() => r'ad82b1bd66146e684d0cdcf2188767a76a58f1f6';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [jobList].
@ProviderFor(jobList)
const jobListProvider = JobListFamily();

/// See also [jobList].
class JobListFamily extends Family<AsyncValue<List<Job>>> {
  /// See also [jobList].
  const JobListFamily();

  /// See also [jobList].
  JobListProvider call({String query = ''}) {
    return JobListProvider(query: query);
  }

  @override
  JobListProvider getProviderOverride(covariant JobListProvider provider) {
    return call(query: provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'jobListProvider';
}

/// See also [jobList].
class JobListProvider extends AutoDisposeFutureProvider<List<Job>> {
  /// See also [jobList].
  JobListProvider({String query = ''})
    : this._internal(
        (ref) => jobList(ref as JobListRef, query: query),
        from: jobListProvider,
        name: r'jobListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$jobListHash,
        dependencies: JobListFamily._dependencies,
        allTransitiveDependencies: JobListFamily._allTransitiveDependencies,
        query: query,
      );

  JobListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Job>> Function(JobListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: JobListProvider._internal(
        (ref) => create(ref as JobListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Job>> createElement() {
    return _JobListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is JobListProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin JobListRef on AutoDisposeFutureProviderRef<List<Job>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _JobListProviderElement
    extends AutoDisposeFutureProviderElement<List<Job>>
    with JobListRef {
  _JobListProviderElement(super.provider);

  @override
  String get query => (origin as JobListProvider).query;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
