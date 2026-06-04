// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$jobListHash() => r'ad9c948b8906360a05174eacb948895a9488c100';

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

/// Fetches all jobs from the mock data source.
/// [query] filters by title or company (case-insensitive); pass empty string for no filter.
///
/// Copied from [jobList].
@ProviderFor(jobList)
const jobListProvider = JobListFamily();

/// Fetches all jobs from the mock data source.
/// [query] filters by title or company (case-insensitive); pass empty string for no filter.
///
/// Copied from [jobList].
class JobListFamily extends Family<AsyncValue<List<Job>>> {
  /// Fetches all jobs from the mock data source.
  /// [query] filters by title or company (case-insensitive); pass empty string for no filter.
  ///
  /// Copied from [jobList].
  const JobListFamily();

  /// Fetches all jobs from the mock data source.
  /// [query] filters by title or company (case-insensitive); pass empty string for no filter.
  ///
  /// Copied from [jobList].
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

/// Fetches all jobs from the mock data source.
/// [query] filters by title or company (case-insensitive); pass empty string for no filter.
///
/// Copied from [jobList].
class JobListProvider extends AutoDisposeFutureProvider<List<Job>> {
  /// Fetches all jobs from the mock data source.
  /// [query] filters by title or company (case-insensitive); pass empty string for no filter.
  ///
  /// Copied from [jobList].
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
