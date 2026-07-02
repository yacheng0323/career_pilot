// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_memo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$jobMemoNotifierHash() => r'a19c6cdb7eedc53f79dc56b13c64a510df572fd5';

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

abstract class _$JobMemoNotifier
    extends BuildlessAutoDisposeAsyncNotifier<JobMemo> {
  late final String jobId;

  FutureOr<JobMemo> build(String jobId);
}

/// See also [JobMemoNotifier].
@ProviderFor(JobMemoNotifier)
const jobMemoNotifierProvider = JobMemoNotifierFamily();

/// See also [JobMemoNotifier].
class JobMemoNotifierFamily extends Family<AsyncValue<JobMemo>> {
  /// See also [JobMemoNotifier].
  const JobMemoNotifierFamily();

  /// See also [JobMemoNotifier].
  JobMemoNotifierProvider call(String jobId) {
    return JobMemoNotifierProvider(jobId);
  }

  @override
  JobMemoNotifierProvider getProviderOverride(
    covariant JobMemoNotifierProvider provider,
  ) {
    return call(provider.jobId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'jobMemoNotifierProvider';
}

/// See also [JobMemoNotifier].
class JobMemoNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<JobMemoNotifier, JobMemo> {
  /// See also [JobMemoNotifier].
  JobMemoNotifierProvider(String jobId)
    : this._internal(
        () => JobMemoNotifier()..jobId = jobId,
        from: jobMemoNotifierProvider,
        name: r'jobMemoNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$jobMemoNotifierHash,
        dependencies: JobMemoNotifierFamily._dependencies,
        allTransitiveDependencies:
            JobMemoNotifierFamily._allTransitiveDependencies,
        jobId: jobId,
      );

  JobMemoNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.jobId,
  }) : super.internal();

  final String jobId;

  @override
  FutureOr<JobMemo> runNotifierBuild(covariant JobMemoNotifier notifier) {
    return notifier.build(jobId);
  }

  @override
  Override overrideWith(JobMemoNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: JobMemoNotifierProvider._internal(
        () => create()..jobId = jobId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        jobId: jobId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<JobMemoNotifier, JobMemo>
  createElement() {
    return _JobMemoNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is JobMemoNotifierProvider && other.jobId == jobId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, jobId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin JobMemoNotifierRef on AutoDisposeAsyncNotifierProviderRef<JobMemo> {
  /// The parameter `jobId` of this provider.
  String get jobId;
}

class _JobMemoNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<JobMemoNotifier, JobMemo>
    with JobMemoNotifierRef {
  _JobMemoNotifierProviderElement(super.provider);

  @override
  String get jobId => (origin as JobMemoNotifierProvider).jobId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
