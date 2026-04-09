import 'external_link_opener_stub.dart'
    if (dart.library.html) 'external_link_opener_web.dart';

Future<void> openExternalLink(String url) => openExternalLinkImpl(url);
