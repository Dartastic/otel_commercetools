// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_commercetools_suppression.dart';

const _tracerName = 'dartastic_otel_libs_commercetools';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class CommercetoolsResult {
  const CommercetoolsResult({
    this.itemCount,
    this.totalCount,
    this.protocol,
    this.projectKey,
    this.storeKey,
    this.orderState,
    this.cartState,
    this.totalAmountMinor,
    this.currency,
    this.versionConflict,
    this.requestId,
    this.statusCode,
  });

  /// `results.length`.
  final int? itemCount;

  /// `total` from list responses.
  final int? totalCount;

  /// `rest` / `graphql` / `import_api` / `audit_log` / `history`.
  final String? protocol;

  /// Project key (multi-tenant routing).
  final String? projectKey;

  /// `in-store` storefront key when present.
  final String? storeKey;

  /// `Open` / `Confirmed` / `Complete` / `Cancelled`.
  final String? orderState;

  /// `Active` / `Merged` / `Ordered` / `Frozen`.
  final String? cartState;

  /// Total in minor units.
  final int? totalAmountMinor;

  /// ISO 4217.
  final String? currency;

  /// `409` ConcurrentModificationException — optimistic-lock conflict
  /// (separate signal from generic 4xx).
  final bool? versionConflict;

  /// `X-Correlation-ID` request id.
  final String? requestId;

  final int? statusCode;
}

class CommercetoolsCallResult<T> {
  const CommercetoolsCallResult({required this.value, this.result});
  final T value;
  final CommercetoolsResult? result;
}

/// Wraps a commercetools API call in a CLIENT span. [operation] is one
/// of `products.query`, `products.get`, `product_projections.search`,
/// `carts.create`, `carts.update`, `carts.add_line_item`,
/// `orders.create_from_cart`, `orders.update`, `orders.cancel`,
/// `customers.query`, `customers.create`, `inventory.entries.query`,
/// `inventory.entries.update`, `discount_codes.query`, `me.signup`,
/// `me.cart`, `import_api.import_sink`, `audit_log.query`.
Future<T> tracedCommercetools<T>({
  required String operation,
  required Future<CommercetoolsCallResult<T>> Function() invoke,
  String? protocol,
  String? projectKey,
}) async {
  if (commercetoolsInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'commercetools',
    'rpc.method': operation,
    'commercetools.operation': operation,
  };
  if (protocol != null) m['commercetools.protocol'] = protocol;
  if (projectKey != null) m['commercetools.project.key'] = projectKey;

  final span = _tracer().startSpan(
    'commercetools $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'commercetools.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalCount != null) {
        extras.add(OTel.attributeInt(
          'commercetools.total',
          r.result!.totalCount!,
        ));
      }
      if (r.result!.protocol != null) {
        extras.add(OTel.attributeString(
          'commercetools.protocol',
          r.result!.protocol!,
        ));
      }
      if (r.result!.projectKey != null) {
        extras.add(OTel.attributeString(
          'commercetools.project.key',
          r.result!.projectKey!,
        ));
      }
      if (r.result!.storeKey != null) {
        extras.add(OTel.attributeString(
          'commercetools.store.key',
          r.result!.storeKey!,
        ));
      }
      if (r.result!.orderState != null) {
        extras.add(OTel.attributeString(
          'commercetools.order.state',
          r.result!.orderState!,
        ));
        if (r.result!.orderState == 'Cancelled') {
          span.setStatus(
            SpanStatusCode.Error,
            'commercetools order cancelled',
          );
        }
      }
      if (r.result!.cartState != null) {
        extras.add(OTel.attributeString(
          'commercetools.cart.state',
          r.result!.cartState!,
        ));
      }
      if (r.result!.totalAmountMinor != null) {
        extras.add(OTel.attributeInt(
          'commercetools.amount.total.minor',
          r.result!.totalAmountMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'commercetools.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.versionConflict != null) {
        extras.add(OTel.attributeBool(
          'commercetools.version_conflict',
          r.result!.versionConflict!,
        ));
        if (r.result!.versionConflict == true) {
          span.setStatus(
            SpanStatusCode.Error,
            'commercetools concurrent modification',
          );
        }
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'commercetools.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400 && r.result!.versionConflict != true) {
          span.setStatus(
            SpanStatusCode.Error,
            'commercetools HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
