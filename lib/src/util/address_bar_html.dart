import 'package:web/web.dart' as html;

String get $hrefPylon => html.window.location.href;

void $pushHrefPylon(data, String title, String? url) =>
    html.window.history.replaceState(data, title, url);
