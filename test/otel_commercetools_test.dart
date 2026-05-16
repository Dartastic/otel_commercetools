// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_commercetools/otel_commercetools.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_commercetools-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('orders.create records protocol + state + amount', () async {
    await tracedCommercetools<String>(
      operation: 'orders.create_from_cart',
      protocol: 'graphql',
      projectKey: 'proj-1',
      invoke: () async => const CommercetoolsCallResult(
        value: 'ok',
        result: CommercetoolsResult(
          protocol: 'graphql',
          projectKey: 'proj-1',
          storeKey: 'us-store',
          orderState: 'Open',
          cartState: 'Ordered',
          totalAmountMinor: 12500,
          currency: 'USD',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('commercetools orders.create_from_cart')!,
    );
    expect(a['commercetools.protocol'], 'graphql');
    expect(a['commercetools.project.key'], 'proj-1');
    expect(a['commercetools.store.key'], 'us-store');
    expect(a['commercetools.order.state'], 'Open');
    expect(a['commercetools.amount.total.minor'], 12500);
  });

  test('version conflict sets span error', () async {
    await tracedCommercetools<String>(
      operation: 'carts.update',
      invoke: () async => const CommercetoolsCallResult(
        value: 'ok',
        result: CommercetoolsResult(
          versionConflict: true,
          statusCode: 409,
        ),
      ),
    );
    expect(
      spans.findSpanByName('commercetools carts.update')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutCommercetoolsInstrumentationAsync(() async {
      await tracedCommercetools<String>(
        operation: 'products.query',
        invoke: () async => const CommercetoolsCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('commercetools '), isEmpty);
  });
}
