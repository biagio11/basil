/// Project details shown in the app and in the legal pages.
library;

const String kAppVersion = '0.2.0';
const String kLegalUpdated = '2026-11-23';
const String kSiteUrl = 'https://basil-bits.netlify.app';
const String kRepoUrl = 'https://github.com/biagio11/basil';
const String kIssuesUrl = 'https://github.com/biagio11/basil/issues';

/// PayPal link for the optional "buy me a coffee" button.
/// Leave empty to hide it.
const String kDonateUrl = 'https://www.paypal.com/paypalme/BiagioTomasetig';

/// Build for Google Play with --dart-define=PLAY_STORE=true. Play does not
/// allow outside payment links, so the coffee button is hidden there.
const bool kPlayBuild = bool.fromEnvironment('PLAY_STORE');
