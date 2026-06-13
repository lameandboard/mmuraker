// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$printerServiceHash() => r'printerServiceHash00000000000000000000';

/// See also [printerService].
@ProviderFor(printerService)
const printerServiceProvider = printerServiceProviderFamily;

const printerServiceProviderFamily =
    _$PrinterServiceFamily();

class _$PrinterServiceFamily
    extends Family<PrinterService> {
  const _$PrinterServiceFamily();

  @override
  String? get name => r'printerServiceProvider';

  @override
  Iterable<ProviderOrFamily>? get dependencies => null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies => null;

  AutoDisposeProvider<PrinterService> call(String machineId) =>
      AutoDisposeProvider<PrinterService>.internal(
        (ref) => printerService(ref, machineId),
        from: this,
        argument: machineId,
        name: r'printerServiceProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$printerServiceHash,
        dependencies: null,
        allTransitiveDependencies: null,
      );

  @override
  String debugFamilyCallString(Object? argument) =>
      'printerServiceProvider($argument)';

  @override
  AutoDisposeProvider<PrinterService> getProviderOverride(
    covariant AutoDisposeProvider<PrinterService> provider,
  ) =>
      call(provider.argument as String);
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef PrinterServiceRef = AutoDisposeProviderRef<PrinterService>;
