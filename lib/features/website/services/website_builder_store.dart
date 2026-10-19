import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/website_builder_draft.dart';
import 'website_builder_api.dart';

enum WebsiteSaveState { idle, saving, saved, error }

/// Local draft persistence with optional backend sync for signed-in users.
class WebsiteBuilderStore {
  WebsiteBuilderStore._();

  static final WebsiteBuilderStore instance = WebsiteBuilderStore._();

  static const prefsKey = 'website_builder_draft_v1';

  final ValueNotifier<WebsiteSaveState> saveState =
      ValueNotifier<WebsiteSaveState>(WebsiteSaveState.idle);

  Timer? _debounce;
  WebsiteBuilderDraft? _latest;

  Future<WebsiteBuilderDraft?> loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return null;
      return WebsiteBuilderDraft.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocal(WebsiteBuilderDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, draft.encode(includeBase64: true));
    } catch (_) {
      // Keep the in-memory draft if storage fails.
    }
  }

  /// Loads remote draft when signed in, otherwise local.
  Future<WebsiteBuilderDraft?> loadPreferred() async {
    final remote = await WebsiteBuilderApi.instance.fetchMine();
    if (remote != null) {
      await saveLocal(remote);
      return remote;
    }
    return loadLocal();
  }

  void scheduleAutosave(WebsiteBuilderDraft draft) {
    _latest = draft;
    _debounce?.cancel();
    saveState.value = WebsiteSaveState.saving;
    _debounce = Timer(const Duration(milliseconds: 900), () {
      unawaited(_flush());
    });
  }

  Future<void> saveNow(WebsiteBuilderDraft draft) async {
    _latest = draft;
    _debounce?.cancel();
    await _flush();
  }

  Future<void> _flush() async {
    final draft = _latest;
    if (draft == null) {
      saveState.value = WebsiteSaveState.idle;
      return;
    }
    saveState.value = WebsiteSaveState.saving;
    await saveLocal(draft);
    final remote = await WebsiteBuilderApi.instance.saveDraft(draft);
    if (remote != null) {
      _latest = remote;
      draft.id = remote.id;
      draft.status = remote.status;
      draft.updatedAt = remote.updatedAt;
      await saveLocal(draft);
    }
    saveState.value = WebsiteSaveState.saved;
  }

  void disposeTimer() {
    _debounce?.cancel();
  }
}
