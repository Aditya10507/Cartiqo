import 'package:url_launcher/url_launcher_string.dart';

Future<void> openExternalLinkImpl(String url) async {
  await launchUrlString(
    url,
    mode: LaunchMode.platformDefault,
    webOnlyWindowName: '_blank',
  );
}
