// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(complaintRemoteDataSource)
final complaintRemoteDataSourceProvider = ComplaintRemoteDataSourceProvider._();

final class ComplaintRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ComplaintRemoteDataSource,
          ComplaintRemoteDataSource,
          ComplaintRemoteDataSource
        >
    with $Provider<ComplaintRemoteDataSource> {
  ComplaintRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'complaintRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$complaintRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ComplaintRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ComplaintRemoteDataSource create(Ref ref) {
    return complaintRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComplaintRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComplaintRemoteDataSource>(value),
    );
  }
}

String _$complaintRemoteDataSourceHash() =>
    r'b9c73b09c5f0aa2ca443aeddf0e40660fad500ee';

@ProviderFor(complaintRepository)
final complaintRepositoryProvider = ComplaintRepositoryProvider._();

final class ComplaintRepositoryProvider
    extends
        $FunctionalProvider<
          ComplaintRepository,
          ComplaintRepository,
          ComplaintRepository
        >
    with $Provider<ComplaintRepository> {
  ComplaintRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'complaintRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$complaintRepositoryHash();

  @$internal
  @override
  $ProviderElement<ComplaintRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ComplaintRepository create(Ref ref) {
    return complaintRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComplaintRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComplaintRepository>(value),
    );
  }
}

String _$complaintRepositoryHash() =>
    r'4097b9a27a8ff83a7b61ba4b042805d99a418abe';

@ProviderFor(studentComplaints)
final studentComplaintsProvider = StudentComplaintsFamily._();

final class StudentComplaintsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ComplaintEntity>>,
          List<ComplaintEntity>,
          Stream<List<ComplaintEntity>>
        >
    with
        $FutureModifier<List<ComplaintEntity>>,
        $StreamProvider<List<ComplaintEntity>> {
  StudentComplaintsProvider._({
    required StudentComplaintsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'studentComplaintsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentComplaintsHash();

  @override
  String toString() {
    return r'studentComplaintsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ComplaintEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ComplaintEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return studentComplaints(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentComplaintsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentComplaintsHash() => r'1d08b54ea62a84a8b857cdb24e795e3490232c9e';

final class StudentComplaintsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ComplaintEntity>>, String> {
  StudentComplaintsFamily._()
    : super(
        retry: null,
        name: r'studentComplaintsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudentComplaintsProvider call(String uid) =>
      StudentComplaintsProvider._(argument: uid, from: this);

  @override
  String toString() => r'studentComplaintsProvider';
}

@ProviderFor(allComplaints)
final allComplaintsProvider = AllComplaintsProvider._();

final class AllComplaintsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ComplaintEntity>>,
          List<ComplaintEntity>,
          Stream<List<ComplaintEntity>>
        >
    with
        $FutureModifier<List<ComplaintEntity>>,
        $StreamProvider<List<ComplaintEntity>> {
  AllComplaintsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allComplaintsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allComplaintsHash();

  @$internal
  @override
  $StreamProviderElement<List<ComplaintEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ComplaintEntity>> create(Ref ref) {
    return allComplaints(ref);
  }
}

String _$allComplaintsHash() => r'37f44d0a2f34d0d60723ca6bc63d52983266c03e';

@ProviderFor(ComplaintAction)
final complaintActionProvider = ComplaintActionProvider._();

final class ComplaintActionProvider
    extends $NotifierProvider<ComplaintAction, AsyncValue<void>> {
  ComplaintActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'complaintActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$complaintActionHash();

  @$internal
  @override
  ComplaintAction create() => ComplaintAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$complaintActionHash() => r'91fba0dd8f02e914a832b957bb87fa2d5293140b';

abstract class _$ComplaintAction extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
