import 'dart:html' as html;

void openExternalLinkImpl(String url) {
  html.window.open(url, '_blank');
}
