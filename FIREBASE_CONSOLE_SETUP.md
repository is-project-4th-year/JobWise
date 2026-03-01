# Firebase Console Setup Guide

Complete these steps in the Firebase Console to enable authentication for your JobWise app.

## Prerequisites
- Firebase project created: `jobwise-f58d5`
- SHA-1 and SHA-256 fingerprints added
- google-services.json downloaded and placed in `android/app/`

---

## Step 1: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **jobwise-f58d5**
3. In the left sidebar, click **Build** → **Authentication**
4. Click the **Get started** button (if first time)
5. Go to the **Sign-in method** tab
6. Click on **Email/Password**
7. Enable the **Email/Password** toggle (first option)
8. **DO NOT** enable "Email link (passwordless sign-in)" for now
9. Click **Save**

**Status:** Email/Password authentication is now enabled ✓

---

## Step 2: Enable Phone Authentication

1. Still in **Authentication** → **Sign-in method** tab
2. Click on **Phone**
3. Enable the **Phone** toggle
4. Click **Save**

**Note:** For production, you may need to:
- Add your app to SafetyNet (for Android)
- Configure reCAPTCHA verification domains
- Set up billing (Firebase Blaze plan) for SMS quotas

**Status:** Phone authentication is now enabled ✓

---

## Step 3: Add Test Phone Numbers (REQUIRED for Development)

For testing without actually sending SMS messages, add test phone numbers:

1. In **Authentication** → **Sign-in method** tab
2. Scroll down to the **Phone numbers for testing** section
3. Click **Add phone number**
4. Add these test numbers with verification codes:

   | Phone Number    | Verification Code |
   |----------------|-------------------|
   | +254700000001  | 123456           |
   | +254700000002  | 123456           |
   | +254700000003  | 123456           |

5. Click **Add** for each number

**Important:**
- Use these numbers during development to avoid SMS charges
- These numbers will instantly verify without sending actual SMS
- Remove or update these before production deployment

**Status:** Test phone numbers configured ✓

---

## Step 4: Configure Authorized Domains

1. In **Authentication** → **Settings** tab
2. Scroll to **Authorized domains**
3. By default, `localhost` should be there for development
4. When deploying, add your production domain

**Status:** Authorized domains configured ✓

---

## Step 5: Set Up Firestore Database

1. In the left sidebar, click **Build** → **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** (for development)
4. Choose your Firestore location (e.g., `us-central`)
5. Click **Enable**

**Security Rules for Development (TEMPORARY):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**To update security rules:**
1. Go to **Firestore Database** → **Rules** tab
2. Replace the rules with the above
3. Click **Publish**

**Important:** Before production, implement proper security rules!

**Status:** Firestore configured ✓

---

## Step 6: Configure Multi-Factor Authentication Settings

1. In **Authentication** → **Settings** tab
2. Scroll to **Multi-factor authentication**
3. **Enrollment:** Select **Optional** (users can choose to enable)
   - OR select **Required** (all users must enable MFA)
4. **Eligible factors:** Ensure **SMS** is checked
5. Click **Save**

**Recommendation:** Start with **Optional** for development

**Status:** MFA settings configured ✓

---

## Step 7: Set SMS Quota (Production Only)

For production use:

1. Upgrade to **Firebase Blaze Plan** (pay-as-you-go)
2. Go to **Authentication** → **Templates** → **SMS**
3. Review default SMS templates
4. Configure SMS quota limits if needed

**Cost:** Firebase includes free tier for SMS:
- First 10,000 verifications/month: Free
- Additional: ~$0.01 per verification

**Status:** Note for production deployment

---

## Step 8: Test Authentication Flow (Optional)

You can test authentication directly in Firebase Console:

1. Go to **Authentication** → **Users** tab
2. Click **Add user**
3. Create a test user with:
   - Email: `test@example.com`
   - Password: `Test123!`
4. Click **Add user**

This user can be used for initial testing.

**Status:** Test user created (optional) ✓

---

## Verification Checklist

Before running your app, verify:

- [ ] Email/Password authentication enabled
- [ ] Phone authentication enabled
- [ ] Test phone numbers added (+254700000001, etc.)
- [ ] Firestore Database created
- [ ] Firestore security rules updated
- [ ] MFA settings configured (Optional/Required)
- [ ] Authorized domains include localhost
- [ ] (Optional) Test user created

---

## Firebase Console URLs

Quick links for your project:

- **Project Overview:** https://console.firebase.google.com/project/jobwise-f58d5
- **Authentication:** https://console.firebase.google.com/project/jobwise-f58d5/authentication
- **Firestore:** https://console.firebase.google.com/project/jobwise-f58d5/firestore
- **Project Settings:** https://console.firebase.google.com/project/jobwise-f58d5/settings/general

---

## Troubleshooting

### "SMS not sent" error
- Verify phone authentication is enabled
- Check if phone number is in test numbers list
- For real numbers: Ensure Firebase Blaze plan is active
- Check SMS quota hasn't been exceeded

### "Invalid verification code" error
- For test numbers: Use the exact code configured (e.g., 123456)
- For real numbers: Check SMS inbox
- Codes expire after 60 seconds

### "Network error" errors
- Check internet connection
- Verify google-services.json is correct
- Ensure Firebase initialization in code

### "User not found" error
- User must sign up first before logging in
- Check if email/password authentication is enabled

---

## Production Checklist

Before going to production:

1. **Update Firestore Rules:**
   - Implement proper security rules
   - Remove test mode rules

2. **Remove Test Phone Numbers:**
   - Delete test numbers from Firebase Console
   - Or reduce them to internal team numbers only

3. **Enable reCAPTCHA:**
   - Configure reCAPTCHA for web
   - Test phone authentication on real devices

4. **Monitor Usage:**
   - Set up Firebase alerts for quota limits
   - Monitor SMS costs in Firebase Console

5. **Update Privacy Policy:**
   - Disclose SMS usage for 2FA
   - Mention Firebase services used

---

## Next Steps

After completing Firebase Console setup:

1. Go back to your project
2. Run `flutter clean && flutter pub get`
3. Run `flutter run`
4. Follow the TESTING_GUIDE.md for testing instructions

**Setup Complete!** 🎉
