# App Store & Play Store Submission Checklist

Copy-paste these exact values into App Store Connect (Apple) and Google Play Console.
App identity is now consistent across the codebase.

---

## App Identity (fixed in code)

| Field | Value |
|-------|-------|
| App Name (display) | India Informations |
| Bundle ID (iOS) | com.indiainformations.app |
| Package (Android) | (see android/app/build.gradle applicationId) |
| Version | 1.0.0 |
| Build | 1 |

---

## APPLE — App Store Connect

### 1. App Information
- **Name:** India Informations
- **Subtitle:** News, Jobs, Tools & Local Explorer
- **Category (Primary):** News  (Secondary: Utilities)
- **Content Rights:** Contains third-party content = No (unless you host others' news verbatim)

### 2. Privacy Policy (App Privacy > Privacy Policy URL)
```
https://indiainformations.com/app-privacy-policy.html
```

### 3. App Privacy (Data collection questionnaire)
Declare that the app collects:
- **Contact Info:** Email address (account), Name — Linked to identity — App Functionality
- **Location:** Coarse/Precise location — NOT linked to identity — App Functionality (nearby places)
- **Identifiers:** Device ID / Advertising ID — Used for Third-Party Advertising (AdMob)
- **Usage Data:** Product interaction — Analytics + Advertising
- **Tracking:** YES (ATT prompt is implemented) — Advertising ID used for tracking

### 4. Support & Marketing URLs
- **Support URL:** `https://indiainformations.com`
- **Marketing URL (optional):** `https://indiainformations.com`

### 5. App Review Information (VERY IMPORTANT for approval)
- **Sign-In required:** Yes
- **Provide a demo/test account:**
  - Email: (create a test account and put it here)
  - Password: (test account password)
- **Notes for reviewer:** (see template at bottom)

### 6. Contact Information (App Review > Contact)
- **First/Last name:** (your name)
- **Phone:** (your phone)
- **Email:** contact@indiainformations.com

### 7. Encryption
- Already set: `ITSAppUsesNonExemptEncryption = false` in Info.plist (only HTTPS, no custom crypto). No extra docs needed.

---

## GOOGLE — Play Console

### 1. Store Listing
- **App name:** India Informations
- **Short description (max 80 chars):**
  ```
  Latest India news, govt jobs, results, 60+ free tools & nearby places.
  ```
- **Full description:** describe ONLY real features: News, Govt Jobs/Results/Admit Cards, Utility Tools (EMI/PDF/QR/Image), Nearby Explorer, Business Directory. Do not overpromise.

### 2. Privacy Policy
```
https://indiainformations.com/app-privacy-policy.html
```

### 3. Data Safety form
Declare collected data:
- Personal info: Name, Email address — Collected, Shared: No — for App functionality & Account management
- Location: Approximate + Precise — Collected — for App functionality (optional, user grants)
- Device/other IDs: Collected/Shared with AdMob — for Advertising
- App activity: interactions — Analytics + Advertising
- **Data encrypted in transit:** Yes
- **User can request deletion:** Yes (in-app "Delete My Account" + email)

### 4. App access (Play review)
- Since login is required for some features, provide a test account:
  - Username: (test email)
  - Password: (test password)
  - Instructions: how to reach the logged-in area

### 5. Content rating
- Fill the questionnaire honestly. Note: app has a "Spin Wheel" + coin rewards.
  Answer the "simulated gambling / rewards" questions accurately.

### 6. Ads
- **Contains ads:** YES (AdMob banner/interstitial/rewarded/native)

### 7. Developer contact (Play Console > Store listing > Contact details)
- **Email:** contact@indiainformations.com
- **Website:** https://indiainformations.com
- **Phone:** (recommended)

---

## Developer Account Settings (BOTH stores) — required for 1.5.0

### Apple Developer account
- Ensure a valid legal entity name + physical address on file.

### Google Play — Developer account > Account details
- **Public developer name:** India Informations
- **Physical address:** (must be a real address — shown publicly)
- **Contact email + phone:** verified

---

## Reviewer Notes Template (paste into both stores' review notes)

```
Thank you for reviewing India Informations.

Overview: A content + utility app for India offering latest news, government
job/result notifications, 60+ free calculators & file tools, a "nearby places"
explorer (uses location only when granted), and a local business directory.

Login: Most content is browsable without an account. A test account is provided
for the profile/rewards/support sections.

Location: Requested only in the Explore tab, foreground only ("when in use"),
to show nearby places. Denying it does not break the app.

Ads: Google AdMob. On iOS, App Tracking Transparency is requested before tracking.

Rewards: In-app coins are earned via daily check-in / spin as an engagement
feature. [Describe here honestly how withdrawal works, or state it is disabled
for this release.]
```

---

## Pre-Upload Reminders (do these before building the release)
1. Confirm the coin -> UPI withdrawal behavior is compliant OR disabled for v1.
2. Replace AdMob TEST IDs with REAL IDs only AFTER approval:
   - lib/services/ad_service.dart
   - android/app/src/main/AndroidManifest.xml (APPLICATION_ID)
   - ios/Runner/Info.plist (GADApplicationIdentifier)
3. Build a signed release (Android App Bundle .aab / iOS archive).
4. Add screenshots that match the actual app screens.
