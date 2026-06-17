import 'package:url_launcher/url_launcher.dart';

/// Opens the device mail composer addressed to [email].
/// Returns false if launching fails (e.g. no mail app).
Future<bool> launchEmail(String email) async {
  final uri = Uri(scheme: 'mailto', path: email);
  try {
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

/// Opens [url] in the external browser. Returns false on failure
/// (unparseable URL or no handler).
Future<bool> launchWebUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
