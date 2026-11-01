# Play Console answers

Drafted from what the app actually does (checked against the code and the merged release
manifest). Play Console → Policy → App content. Each section matches a form there.

If the app changes, update this file first: these answers must stay true, and the privacy
policy (`docs/privacy.html`) must say the same thing.

## Data safety

### Overview questions

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | Names, email, user IDs and expense records |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | Firebase talks HTTPS only |
| Which account creation methods does your app support? | **OAuth** (Sign in with Google) | Guests get an anonymous ID; no username/password |
| Do you provide a way for users to request that their data is deleted? | **Yes** | In app: Account → Delete account. Web: https://atharavmishra.github.io/FairSplit/delete-account.html |

### Data types

Tick only these. "Shared" is **No** for all: Firebase processes data on our behalf (a
service provider), and group members seeing a group's data is user-initiated sharing,
which Play excludes.

| Category → type | Collected | Required or optional | Purposes | Processed ephemerally? |
|---|---|---|---|---|
| Personal info → **Name** | Yes | Optional (from Google; member names are typed by users) | App functionality, Account management | No |
| Personal info → **Email address** | Yes | Optional (only with Google sign-in) | Account management | No |
| Personal info → **User IDs** | Yes | Required (Firebase account ID, guest or Google) | App functionality, Account management | No |
| Financial info → **Other financial info** | Yes | Required to use the app | App functionality | No |

"Other financial info" covers expense amounts, who paid, splits, settle-up records and
optional UPI IDs. FairSplit takes no card, bank or purchase-history data.

The Google profile photo is only a link in the Firebase Auth profile, loaded from Google to
show on the Account screen. FairSplit never uploads or stores image files, so "Photos" does
not apply. The privacy policy still mentions the photo, to be open about it.

### Do not tick

Location, contacts, phone number, messages, photos and videos, audio, files, calendar,
health, web browsing, app activity, installed apps, device or other IDs (no advertising ID:
the manifest has no `AD_ID` permission), crash logs and diagnostics.

> **When Crashlytics ships (task 19), add:** App info and performance → **Crash logs** and
> **Diagnostics**: collected, not shared, required, purpose *Analytics*. Also add a line to
> the privacy policy before that release.

## Content rating (IARC questionnaire)

| Question | Answer |
|---|---|
| Email for the rating certificate | atharvmishra77@gmail.com |
| Category | All other app types (utility / productivity) |
| Violence, fear, sexuality, language, controlled substances, crude humour | No to all |
| Gambling or simulated gambling | No |
| Does the app let users interact or exchange content? | **Yes**. Group members see each other's names and expenses |
| Does the app share the user's current physical location with other users? | No |
| Does the app allow users to purchase digital goods? | No |
| Is the app a web browser or search engine? | No |

Expected result: Everyone / PEGI 3 / IARC 3+, with a "Users Interact" notice.

## Target audience and content

| Question | Answer | Why |
|---|---|---|
| Target age groups | **18 and over** | A money-tracking tool for adults; keeps the app out of the Families policy. The privacy policy already says it isn't for under-13s |
| Could the app unintentionally appeal to children? | No | |
| Store presence: appeals to children? | No | |

## Other declarations

| Form | Answer | Notes |
|---|---|---|
| Privacy policy | https://atharavmishra.github.io/FairSplit/privacy.html | |
| Ads | **No, my app does not contain ads** | |
| App access | **All functionality is available without special access** | Guests can use everything; no login details needed for review |
| Advertising ID | **No** | No `com.google.android.gms.permission.AD_ID` in the release manifest |
| Government app | No | |
| Financial features | **My app doesn't provide any financial features** | It records shared costs and opens the user's own UPI app; it doesn't move, hold, lend or invest money. If Play's review disagrees, the closest fit is a personal-finance/budgeting tool, not payments |
| Health apps | No health features | |
| News app | No | |

## Release manifest permissions (for reference)

`INTERNET` and `ACCESS_NETWORK_STATE` (Firebase), `USE_BIOMETRIC` and `USE_FINGERPRINT`
(added by Google's Credential Manager library for sign-in; FairSplit never asks for a
fingerprint), `READ_GSERVICES` (Google Play services). None need a declaration form.
