// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$applyStatusNotifierHash() =>
    r'91d42741cdce6c251a53dda7219de710f8879223';

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

abstract class _$ApplyStatusNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ApplyStatus> {
  late final String jobId;

  FutureOr<ApplyStatus> build(String jobId);
}

/// See also [ApplyStatusNotifier].
@ProviderFor(ApplyStatusNotifier)
const applyStatusNotifierProvider = ApplyStatusNotifierFamily();

/// See also [ApplyStatusNotifier].
class ApplyStatusNotifierFamily extends Family<AsyncValue<ApplyStatus>> {
  /// See also [ApplyStatusNotifier].
  const ApplyStatusNotifierFamily();

  /// See also [ApplyStatusNotifier].
  ApplyStatusNotifierProvider call(String jobId) {
    return ApplyStatusNotifierProvider(jobId);
  }

  @override
  ApplyStatusNotifierProvider getProviderOverride(
    covariant ApplyStatusNotifierProvider provider,
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
  String? get name => r'applyStatusNotifierProvider';
}

/// See also [ApplyStatusNotifier].
class ApplyStatusNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<ApplyStatusNotifier, ApplyStatus> {
  /// See also [ApplyStatusNotifier].
  ApplyStatusNotifierProvider(String jobId)
    : this._internal(
        () => ApplyStatusNotifier()..jobId = jobId,
        from: applyStatusNotifierProvider,
        name: r'applyStatusNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$applyStatusNotifierHash,
        dependencies: ApplyStatusNotifierFamily._dependencies,
        allTransitiveDependencies:
            ApplyStatusNotifierFamily._allTransitiveDependencies,
        jobId: jobId,
      );

  ApplyStatusNotifierProvider._internal(
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
  FutureOr<ApplyStatus> runNotifierBuild(
    covariant ApplyStatusNotifier notifier,
  ) {
    return notifier.build(jobId);
  }

  @override
  Override overrideWith(ApplyStatusNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ApplyStatusNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ApplyStatusNotifier, ApplyStatus>
  createElement() {
    return _ApplyStatusNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ApplyStatusNotifierProvider && other.jobId == jobId;
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
mixin ApplyStatusNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<ApplyStatus> {
  /// The parameter `jobId` of this provider.
  String get jobId;
}

class _ApplyStatusNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ApplyStatusNotifier,
          ApplyStatus
        >
    with ApplyStatusNotifierRef {
  _ApplyStatusNotifierProviderElement(super.provider);

  @override
  String get jobId => (origin as ApplyStatusNotifierProvider).jobId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
