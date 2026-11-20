import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_text_field.dart';
import 'blue_tik_art.dart';
import 'blue_tik_models.dart';

class BlueTikBookingScreen extends StatefulWidget {
  const BlueTikBookingScreen({
    required this.offer,
    this.initialName = '',
    this.initialMobile = '',
    this.initialEmail = '',
    super.key,
  });

  final BlueTikOffer offer;
  final String initialName;
  final String initialMobile;
  final String initialEmail;

  @override
  State<BlueTikBookingScreen> createState() => _BlueTikBookingScreenState();
}

class _BlueTikBookingScreenState extends State<BlueTikBookingScreen> {
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final Map<String, TextEditingController> _urls;
  var _errors = const BlueTikValidation();
  BlueTikApplication? _submitted;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _mobile = TextEditingController(text: widget.initialMobile);
    _email = TextEditingController(text: widget.initialEmail);
    _urls = {
      for (final id in widget.offer.platforms) id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    for (final controller in _urls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final urls = {for (final id in widget.offer.platforms) id: _urls[id]!.text};
    final errors = validateBlueTikRequest(
      name: _name.text,
      mobile: _mobile.text,
      email: _email.text,
      profileUrls: urls,
    );
    if (!errors.isValid) {
      setState(() => _errors = errors);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final application = BlueTikApplication(
      offerId: widget.offer.id,
      serviceName: blueTikServiceTitle(l10n, widget.offer),
      priceInr: widget.offer.priceInr,
      leaderName: _name.text.trim(),
      mobile: AuthService.normalizePhone(_mobile.text)!,
      email: _email.text.trim(),
      profileUrls: {
        for (final entry in urls.entries) entry.key: entry.value.trim(),
      },
      submittedAt: DateTime.now(),
    );
    BlueTikApplicationStore.instance.add(application);
    setState(() {
      _errors = const BlueTikValidation();
      _submitted = application;
    });
  }

  String? _message(AppLocalizations l10n, String? code) {
    return switch (code) {
      'name_required' => l10n.line('blueTikNameRequired'),
      'mobile_invalid' => l10n.line('blueTikMobileInvalid'),
      'email_invalid' => l10n.line('blueTikEmailInvalid'),
      'url_invalid' => l10n.line('blueTikUrlInvalid'),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _submitted;
    return Scaffold(
      key: Key(
        submitted == null ? 'blue-tik-booking' : 'blue-tik-confirmation',
      ),
      backgroundColor: BlueTikTone.of(context).card,
      body: BlueTikPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 28 : 16,
                  8,
                  wide ? 28 : 16,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child:
                        submitted == null
                            ? _Form(
                              offer: widget.offer,
                              wide: wide,
                              name: _name,
                              mobile: _mobile,
                              email: _email,
                              urls: _urls,
                              errors: _errors,
                              message: _message,
                              onBack: () => Navigator.of(context).pop(),
                              onSubmit: _submit,
                            )
                            : _Confirmation(
                              application: submitted,
                              onDone: () => Navigator.of(context).pop(),
                            ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.offer,
    required this.wide,
    required this.name,
    required this.mobile,
    required this.email,
    required this.urls,
    required this.errors,
    required this.message,
    required this.onBack,
    required this.onSubmit,
  });

  final BlueTikOffer offer;
  final bool wide;
  final TextEditingController name;
  final TextEditingController mobile;
  final TextEditingController email;
  final Map<String, TextEditingController> urls;
  final BlueTikValidation errors;
  final String? Function(AppLocalizations l10n, String? code) message;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = BlueTikTone.of(context);
    final title = blueTikServiceTitle(l10n, offer);
    final description = blueTikServiceDescription(l10n, offer);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tone.shadow,
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 8, wide ? 24 : 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BlueTikBackButton(onPressed: onBack),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.line('blueTikFormTitle'),
              style: TextStyle(
                color: tone.navy,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            _SelectedService(
              offer: offer,
              title: title,
              description: description,
              note: l10n.line('blueTikAssistanceNote'),
              selectedLabel: l10n.line('blueTikSelected'),
            ),
            const SizedBox(height: 18),
            AppTextField(
              key: const Key('blue-tik-name'),
              controller: name,
              label: l10n.line('blueTikLeaderName'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              errorText: message(l10n, errors.name),
            ),
            const SizedBox(height: 14),
            AppTextField(
              key: const Key('blue-tik-mobile'),
              controller: mobile,
              label: l10n.line('blueTikMobile'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              ],
              errorText: message(l10n, errors.mobile),
            ),
            const SizedBox(height: 14),
            AppTextField(
              key: const Key('blue-tik-email'),
              controller: email,
              label: l10n.line('blueTikEmail'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              errorText: message(l10n, errors.email),
            ),
            for (final id in offer.platforms) ...[
              const SizedBox(height: 14),
              AppTextField(
                key: Key('blue-tik-url-$id'),
                controller: urls[id]!,
                label: blueTikProfileUrlLabel(l10n, id),
                keyboardType: TextInputType.url,
                textInputAction:
                    id == offer.platforms.last
                        ? TextInputAction.done
                        : TextInputAction.next,
                autofillHints: const [AutofillHints.url],
                errorText: message(l10n, errors.urls[id]),
                onSubmitted:
                    id == offer.platforms.last ? (_) => onSubmit() : null,
              ),
            ],
            const SizedBox(height: 20),
            BlueTikPillButton(
              key: const Key('blue-tik-submit'),
              label: l10n.line('blueTikSubmit'),
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedService extends StatelessWidget {
  const _SelectedService({
    required this.offer,
    required this.title,
    required this.description,
    required this.note,
    required this.selectedLabel,
  });

  final BlueTikOffer offer;
  final String title;
  final String description;
  final String note;
  final String selectedLabel;

  @override
  Widget build(BuildContext context) {
    final tone = BlueTikTone.of(context);
    final marks =
        offer.bundle
            ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlueTikMark('instagram', size: 28),
                SizedBox(width: 6),
                BlueTikMark('facebook', size: 28),
                SizedBox(width: 6),
                BlueTikMark('whatsapp', size: 28),
              ],
            )
            : BlueTikMark(offer.id, size: 46);
    return Container(
      key: const Key('blue-tik-selected'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          marks,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedLabel,
                  style: TextStyle(
                    color: tone.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: tone.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: tone.muted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formatInr(offer.priceInr),
                  style: TextStyle(
                    color: tone.blue,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: TextStyle(
                    color: tone.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.application, required this.onDone});

  final BlueTikApplication application;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = BlueTikTone.of(context);
    final body = l10n
        .line('blueTikConfirmBody')
        .replaceAll('{service}', application.serviceName)
        .replaceAll('{price}', formatInr(application.priceInr));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tone.shadow,
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFFB7791F),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.line('blueTikConfirmTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tone.navy,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: tone.muted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              application.leaderName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tone.navy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const Key('blue-tik-status'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.line('blueTikStatusPending'),
                style: const TextStyle(
                  color: Color(0xFF9A6700),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.line('blueTikPendingNote'),
              textAlign: TextAlign.center,
              style: TextStyle(color: tone.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: BlueTikPillButton(
                key: const Key('blue-tik-done'),
                label: l10n.line('blueTikDone'),
                onPressed: onDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
