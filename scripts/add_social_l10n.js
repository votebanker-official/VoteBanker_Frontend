const fs = require("fs");
const path = require("path");

const keys = {
  socialConnectTitle: "Connect {provider}",
  socialSecureTitle: "Secure authorization",
  socialPermissionsTitle: "Required permissions",
  socialRedirectNote: "You'll be redirected to {provider} to authorize the connection.",
  socialContinueTo: "Continue to {provider}",
  socialCancel: "Cancel",
  socialRetry: "Retry",
  socialConnecting: "Connecting...",
  socialConnectingHint: "Please wait while we verify your account with {provider}.",
  socialConnectedTitle: "Connected successfully",
  socialConnectedHeading: "{provider} connected",
  socialConnectedBody: "Your {provider} account is connected successfully.",
  socialConnectedBadge: "Connected",
  socialDone: "Done",
  socialManage: "Manage",
  socialDisconnect: "Disconnect",
  socialNotSignedIn: "Sign in to VOTE BANKER before connecting a social account.",
  socialNotConfiguredProvider:
    "This provider is not configured yet. Add the official developer credentials on the backend.",
  socialCancelled: "Authorization was cancelled. The account was not connected.",
  socialFailedConnect: "Authorization failed. Try again from the official provider page.",
  socialNoPage: "Connect a Facebook Page you manage. Personal profile publishing is not supported.",
  socialProfessionalRequired: "Connect a professional Instagram account. Personal accounts are not supported.",
  socialNoChannel: "No YouTube channel was found on the authorized Google account.",
  socialWhatsappIncomplete:
    "WhatsApp Business messaging was not completed. A Business account and phone number are required.",
  socialStorageNotReady: "Connection storage is not ready. Apply the social_account_connections migration.",
  socialIgSummary: "Connect your Instagram account to manage your political outreach from VOTE BANKER.",
  socialIgSecure: "Sign in through the official Instagram/Meta platform. We never ask for your password.",
  socialIgPermissions:
    "We request your professional profile info, username, and account identity so we can show the connected account.",
  socialFbSummary: "Connect your Facebook Page to manage your political outreach from VOTE BANKER.",
  socialFbSecure: "Sign in through the official Facebook platform. We never ask for your password.",
  socialFbPermissions:
    "We request the Pages you manage. Personal Facebook profile publishing is not supported.",
  socialWaSummary: "Connect your WhatsApp Business account for official Cloud API messaging.",
  socialWaSecure: "Authorize through Meta Embedded Signup. We never ask for your WhatsApp password.",
  socialWaPermissions:
    "We request the WhatsApp Business Account and phone number used for Cloud API messaging. This does not publish WhatsApp Status.",
  socialXSummary: "Connect your X account to manage your political outreach from VOTE BANKER.",
  socialXSecure: "Sign in through the official X platform. We never ask for your password.",
  socialXPermissions: "We request your public profile information so we can show the connected account.",
  socialYtSummary: "Connect your YouTube channel to manage your political outreach from VOTE BANKER.",
  socialYtSecure: "Sign in through Google's official platform. We never ask for your password.",
  socialYtPermissions: "We request your channel information so we can show the authorized YouTube channel.",
  socialEmailSummary: "Connect your email account to manage your campaign communication from VOTE BANKER.",
  socialEmailSecure: "Sign in through Google using official OAuth. We never ask for your email password.",
  socialEmailPermissions: "We request your email address and basic profile. No email password is stored.",
};

const files = ["en.dart", "hi.dart", "kn.dart", "ml.dart", "ta.dart", "te.dart"];
const dir = path.join(__dirname, "..", "lib", "app", "localization", "translations");

for (const file of files) {
  const full = path.join(dir, file);
  let text = fs.readFileSync(full, "utf8");
  const additions = [];
  for (const [key, value] of Object.entries(keys)) {
    if (text.includes(`'${key}':`)) continue;
    additions.push(`  '${key}': '${value.replace(/'/g, "\\'")}',`);
  }
  if (!additions.length) continue;
  text = text.replace(/\n};\s*$/, `\n${additions.join("\n")}\n};\n`);
  fs.writeFileSync(full, text, "utf8");
}
