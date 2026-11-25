import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/web_file_downloader.dart';
import '../../domain/entities/score_audit_log_entry.dart';
import 'audit_log_providers.dart';

/// Controller managing CSV/JSON export downloads and manual yearly audit log
/// cleanup (`DELETE` on `score_audit_logs` only).
class AuditLogController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  bool exportEntries({
    required List<ScoreAuditLogEntry> entries,
    required bool asJson,
    int? yearBe,
    String? academicYearId,
  }) {
    final exporter = ref.read(auditLogExportServiceProvider);
    final now = DateTime.now();
    final content = asJson
        ? exporter.buildJsonContent(entries, yearBe: yearBe, exportedAt: now)
        : exporter.buildCsvContent(entries);
    final filename = exporter.buildExportFileName(
      yearBe: yearBe,
      extension: asJson ? 'json' : 'csv',
      now: now,
    );
    final bytes = Uint8List.fromList(utf8.encode(content));
    final triggered = downloadBytesInBrowser(
      bytes: bytes,
      filename: filename,
      mimeType: asJson
          ? 'application/json;charset=utf-8'
          : 'text/csv;charset=utf-8',
    );
    if (academicYearId != null) {
      ref
          .read(exportedAuditLogYearIdsProvider.notifier)
          .markExported(academicYearId);
    }
    return triggered;
  }

  Future<int?> exportYearLogs({
    required String academicYearId,
    required int yearBe,
    required bool asJson,
  }) async {
    return _run<int>(() async {
      final entries = await ref
          .read(auditLogRepositoryProvider)
          .fetchAuditLogs(academicYearId: academicYearId, limit: 10000);
      exportEntries(
        entries: entries,
        asJson: asJson,
        yearBe: yearBe,
        academicYearId: academicYearId,
      );
      return entries.length;
    });
  }

  /// Deletes ONLY `public.score_audit_logs` rows for [academicYearId].
  Future<int?> deleteLogsForAcademicYear(String academicYearId) async {
    return _run<int>(() async {
      final deletedCount = await ref
          .read(auditLogRepositoryProvider)
          .deleteAuditLogsByAcademicYear(academicYearId);
      ref
        ..invalidate(auditLogEntriesProvider)
        ..invalidate(auditLogYearSummariesProvider);
      return deletedCount;
    });
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading<void>();
    try {
      final result = await action();
      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return null;
    }
  }
}

final auditLogControllerProvider =
    NotifierProvider<AuditLogController, AsyncValue<void>>(
      AuditLogController.new,
    );
