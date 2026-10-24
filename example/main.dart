// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_commercetools/otel_commercetools.dart';

/// Traces commercetools calls with OpenTelemetry.
///
/// `otel_commercetools` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each commercetools call in
/// [tracedCommercetools]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'commercetools-example');

  // Wraps a commercetools API call in a CLIENT span.
  final commercetoolsId = await tracedCommercetools<String>(
    operation: 'carts.create',
    protocol: 'example',
    projectKey: 'orders/2026/inv-1042.pdf',
    invoke: () async {
      // Make the commercetools call here, then report what it returned.
      const id = 'commercetools_8f3a2c';
      return const CommercetoolsCallResult(
          value: id,
          result: CommercetoolsResult(
              itemCount: 3,
              totalCount: 3,
              protocol: 'rest',
              projectKey: 'orders/2026/inv-1042.pdf',
              storeKey: 'in-store',
              orderState: 'Open',
              cartState: 'Active',
              totalAmountMinor: 1999,
              currency: 'usd',
              versionConflict: true,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedCommercetools carts.create returned $commercetoolsId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCommercetoolsInstrumentationAsync.
  await runWithoutCommercetoolsInstrumentationAsync(
    () => tracedCommercetools<String>(
      operation: 'carts.create',
      protocol: 'example',
      projectKey: 'orders/2026/inv-1042.pdf',
      invoke: () async {
        const id = 'commercetools_8f3a2c';
        return const CommercetoolsCallResult(
            value: id,
            result: CommercetoolsResult(
                itemCount: 3,
                totalCount: 3,
                protocol: 'rest',
                projectKey: 'orders/2026/inv-1042.pdf',
                storeKey: 'in-store',
                orderState: 'Open',
                cartState: 'Active',
                totalAmountMinor: 1999,
                currency: 'usd',
                versionConflict: true,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
