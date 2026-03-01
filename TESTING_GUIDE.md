# Testing Guide - Firebase Authentication with MFA

This guide provides step-by-step instructions for testing all authentication flows in your JobWise app.

---

## Prerequisites

Before testing, ensure:
- [ ] Firebase Console setup completed (see FIREBASE_CONSOLE_SETUP.md)
- [ ] Test phone numbers added to Firebase Console
- [ ] App compiled and running on device/emulator
- [ ] Internet connection active

---

## Test Scenario 1: New User Signup with Phone Verification

### Objective
Test complete signup flow with phone verification and MFA enrollment.

### Steps

1. **Launch the app**
   - You should see the Login screen

2. **Navigate to Signup**
   - Tap "Sign Up" button at the bottom

3. **Fill in signup form:**
   - **Email:** `testuser1@example.com`
   - **Password:** `Test123!@#`
   - **Confirm Password:** `Test123!@#`
   - **Phone Number:** `+254700000001` (or `0700000001`)
   - Tap "Sign Up"

4. **Verify signup success**
   - Should see success message: "Account created! Please verify your phone number."
   - Should automatically navigate to Phone Verification screen

5. **Send verification code**
   - Phone number field should be pre-filled with `+254700000001`
   - Tap "Send Code"
   - Should see: "Verification code sent to +254 *** *** 001"

6. **Enter verification code**
   - Enter code: `123456` (test number code from Firebase Console)
   - Code should auto-submit when 6 digits entered
   - OR tap "Verify Code" button

7. **Verify MFA enrollment**
   - Should see: "Phone verified and MFA enabled!"
   - Should navigate to Dashboard screen

8. **Verify dashboard access**
   - Should see: "Hi testuser1, ready to practice today?"
   - User is now fully authenticated with MFA

**Expected Result:** ✅ User created, phone verified, MFA enrolled, logged in

---

## Test Scenario 2: Existing User Login with MFA Challenge

### Objective
Test login flow for user with MFA enabled.

### Steps

1. **Logout from dashboard**
   - Tap logout icon (top-right)
   - Confirm logout
   - Should return to Login screen

2. **Login with credentials**
   - **Email:** `testuser1@example.com`
   - **Password:** `Test123!@#`
   - Tap "Login"

3. **Verify MFA challenge triggered**
   - Should see "Two-Factor Authentication" screen
   - Should see: "Verification code sent to +254 *** *** 001"

4. **Enter MFA code**
   - Enter code: `123456`
   - Code should auto-submit or tap "Verify"

5. **Verify login success**
   - Should see: "Authentication successful!"
   - Should navigate to Dashboard

**Expected Result:** ✅ MFA challenge completed, user logged in

---

## Test Scenario 3: Password Reset Flow

### Objective
Test password reset functionality.

### Steps

1. **From Login screen**
   - Tap "Forgot Password?"

2. **Enter email**
   - **Email:** `testuser1@example.com`
   - Tap "Send Reset Link"

3. **Verify email sent**
   - Should see: "Password reset email sent to testuser1@example.com"
   - Check email inbox for reset link

4. **Reset password**
   - Click link in email
   - Enter new password in Firebase page
   - Return to app

5. **Login with new password**
   - Should be able to login with new password

**Expected Result:** ✅ Password reset email sent and processed

---

## Test Scenario 4: Phone Number Format Handling

### Objective
Test phone number validation and auto-formatting.

### Steps

1. **Signup with different phone formats**

   Test these formats (all should work):
   - `0712345678` → auto-converts to `+254712345678`
   - `712345678` → auto-converts to `+254712345678`
   - `+254712345678` → stays as is
   - `254712345678` → auto-converts to `+254712345678`

2. **Test invalid formats**

   These should show validation errors:
   - `123456` → "Phone number must be 9 digits after country code"
   - `+255712345678` → "Phone number must be a Kenyan number (+254)"
   - `+254812345678` → "Phone number must start with +2547 or +2541"

**Expected Result:** ✅ Valid formats accepted, invalid formats rejected

---

## Test Scenario 5: Code Resend Functionality

### Objective
Test OTP code resending with countdown timer.

### Steps

1. **Start phone verification**
   - Signup or trigger phone verification
   - Send initial code

2. **Check resend button**
   - "Resend Code" should be disabled
   - Should show countdown: "Resend Code (60 s)"

3. **Wait for countdown**
   - Counter decrements each second
   - After 60 seconds, button becomes enabled

4. **Resend code**
   - Tap "Resend Code"
   - Should see: "Verification code sent..."
   - Countdown starts again

**Expected Result:** ✅ Resend works with proper countdown

---

## Test Scenario 6: Error Handling

### Objective
Test various error scenarios and user-friendly messages.

### Test Cases

#### A. Invalid Login Credentials
- **Email:** `testuser1@example.com`
- **Password:** `wrongpassword`
- **Expected:** "Incorrect password. Please try again."

#### B. User Not Found
- **Email:** `nonexistent@example.com`
- **Password:** `anything`
- **Expected:** "No account found with this email. Please sign up."

#### C. Email Already in Use
- Try signing up with existing email
- **Expected:** "This email is already registered. Please sign in instead."

#### D. Weak Password
- Try signup with password: `123`
- **Expected:** "Password is too weak. Please use at least 6 characters."

#### E. Invalid Email Format
- Try signup with email: `notanemail`
- **Expected:** "Enter a valid email address"

#### F. Password Mismatch
- Password: `Test123!`
- Confirm: `Test456!`
- **Expected:** "Passwords do not match"

#### G. Invalid OTP Code
- Enter wrong code: `000000`
- **Expected:** "Invalid verification code. Please check and try again."

#### H. Network Error
- Turn off internet
- Try any operation
- **Expected:** "Network error. Please check your internet connection."

**Expected Result:** ✅ All errors show user-friendly messages

---

## Test Scenario 7: Navigation Flow

### Objective
Test all navigation paths work correctly.

### Navigation Map

```
Login Screen
├─> Signup Screen ──> Phone Verification ──> Dashboard
├─> Password Reset ──> (back to) Login
└─> (after login) ──> MFA Challenge ──> Dashboard

Dashboard
└─> Logout ──> Login Screen
```

### Test Each Path

1. **Login → Signup → Phone Verification → Dashboard**
2. **Login → Password Reset → Login**
3. **Login → MFA Challenge → Dashboard**
4. **Dashboard → Logout → Login**

**Expected Result:** ✅ All navigation paths work smoothly

---

## Test Scenario 8: UI/UX Testing

### Objective
Verify UI polish and user experience.

### Checks

- [ ] Password visibility toggle works (eye icon)
- [ ] Password strength indicator shows correct colors:
  - Red: Too short / Weak
  - Orange: Weak
  - Blue: Good / Medium
  - Green: Strong
- [ ] Loading indicators show during async operations
- [ ] Form validation provides real-time feedback
- [ ] Pinput OTP fields highlight correctly
- [ ] Buttons are disabled during loading
- [ ] Success messages are green
- [ ] Error messages are red
- [ ] Navigation is smooth without flashing

**Expected Result:** ✅ UI is polished and responsive

---

## Test Scenario 9: Session Persistence

### Objective
Test that user stays logged in after app restart.

### Steps

1. **Login to the app**
   - Complete full login flow

2. **Close the app completely**
   - Don't just minimize - force close

3. **Reopen the app**
   - Should go directly to Dashboard
   - Should NOT ask to login again

4. **Test logout persistence**
   - Logout from dashboard
   - Close app
   - Reopen app
   - Should show Login screen

**Expected Result:** ✅ Session persists correctly

---

## Test Scenario 10: Multiple Users

### Objective
Test switching between different user accounts.

### Steps

1. **Create User 1**
   - Email: `user1@test.com`
   - Phone: `+254700000001`

2. **Logout and create User 2**
   - Email: `user2@test.com`
   - Phone: `+254700000002`

3. **Verify both accounts in Firebase Console**
   - Go to Authentication → Users
   - Should see both users listed

4. **Login with User 1**
   - Should work with MFA

5. **Logout and login with User 2**
   - Should work with MFA

**Expected Result:** ✅ Multiple accounts work independently

---

## Debug Panel (Development Only)

### Access Debug Information

The app includes debug logging in development mode. Check console output for:

```
[AuthService] Starting sign up for email: user@example.com
[AuthService] Sign up successful for user: uid123...
[AuthBloc] Sign up requested for: user@example.com
[FirestoreService] Creating user document for user: uid123...
```

### Check Firestore Data

1. Go to Firebase Console → Firestore Database
2. Open `users` collection
3. Find your user document by UID
4. Verify fields:
   - `email`
   - `phoneNumber`
   - `isPhoneVerified: true`
   - `isMFAEnabled: true`
   - `createdAt`
   - `lastLogin`

---

## Common Issues and Solutions

### Issue: "SMS not sent"
**Solution:**
- Verify phone number is in test numbers list in Firebase Console
- Check format: `+254700000001`

### Issue: "Code doesn't work"
**Solution:**
- For test numbers, use exactly `123456` (or code from Firebase Console)
- Codes expire after 60 seconds - request new one

### Issue: "App crashes on startup"
**Solution:**
- Run `flutter clean && flutter pub get`
- Check Firebase initialization in main.dart
- Verify google-services.json is in android/app/

### Issue: "Phone verification screen doesn't appear"
**Solution:**
- Check Firestore - user document should have `isPhoneVerified: false`
- Check AuthBloc state transitions in debug logs

### Issue: "MFA not triggering on login"
**Solution:**
- Verify phone was verified and MFA enrolled
- Check Firestore: `isMFAEnabled` should be `true`
- Check Firebase Auth console for MFA enrollment

---

## Performance Testing

### Loading Times (Expected)

- App startup: < 2 seconds
- Signup: < 3 seconds
- Login (no MFA): < 2 seconds
- Login (with MFA): < 2 seconds + OTP entry time
- Send OTP: < 2 seconds
- Verify OTP: < 2 seconds
- Password reset email: < 2 seconds

If any operation takes > 5 seconds, check:
- Internet connection speed
- Firebase region (should be nearby)
- Device performance

---

## Security Testing

### Verify Security Features

- [ ] Passwords are never displayed in plain text
- [ ] Password fields use obscureText
- [ ] Phone numbers are masked in messages (+254 *** *** 789)
- [ ] Sensitive fields clear on errors
- [ ] Session tokens are properly managed
- [ ] Logout clears all session data

---

## Production Testing Checklist

Before deploying to production:

- [ ] Test with real phone numbers (not test numbers)
- [ ] Verify SMS costs and quotas
- [ ] Test on multiple devices (Android versions)
- [ ] Test with poor network conditions
- [ ] Test form validation edge cases
- [ ] Test with screen readers (accessibility)
- [ ] Test landscape orientation
- [ ] Review all error messages for clarity
- [ ] Verify Firestore security rules
- [ ] Test account deletion flow (if implemented)

---

## Automated Testing (Future)

Consider adding:

```dart
// Example widget test
testWidgets('Login form validation', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());

  // Find email and password fields
  final emailField = find.byType(TextField).first;
  final passwordField = find.byType(TextField).last;

  // Enter invalid email
  await tester.enterText(emailField, 'invalid');
  await tester.tap(find.text('Login'));
  await tester.pump();

  // Verify error message
  expect(find.text('Enter a valid email address'), findsOneWidget);
});
```

---

## Test Results Template

Use this to track your testing:

```
[ ] Scenario 1: New User Signup - PASS/FAIL
[ ] Scenario 2: Login with MFA - PASS/FAIL
[ ] Scenario 3: Password Reset - PASS/FAIL
[ ] Scenario 4: Phone Formats - PASS/FAIL
[ ] Scenario 5: Code Resend - PASS/FAIL
[ ] Scenario 6: Error Handling - PASS/FAIL
[ ] Scenario 7: Navigation - PASS/FAIL
[ ] Scenario 8: UI/UX - PASS/FAIL
[ ] Scenario 9: Session Persistence - PASS/FAIL
[ ] Scenario 10: Multiple Users - PASS/FAIL

Notes:
_________________________________
_________________________________
```

---

## Support and Debugging

If you encounter issues:

1. Check debug console logs
2. Verify Firebase Console setup
3. Check internet connection
4. Review FIREBASE_CONSOLE_SETUP.md
5. Clear app data and try again
6. Run `flutter clean && flutter pub get`

---

**Happy Testing!** 🧪
