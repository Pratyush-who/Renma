# Renma Auth Integration Guide for Flutter

This guide documents the current Spring Boot authentication API and how the Flutter app should call it.

## Base URL

Use the backend host where Spring Boot is running:

```text
http://localhost:8080
```

For Android emulator, use:

```text
http://10.0.2.2:8080
```

For a physical phone, use the computer LAN IP, for example:

```text
http://192.168.1.10:8080
```

All request bodies below are JSON. Send this header on every JSON request:

```http
Content-Type: application/json
```

Protected endpoints also require:

```http
Authorization: Bearer <jwt_token>
```

## Important Backend Behavior

- Most auth endpoints return plain text success or error messages.
- Login and Google auth return JSON:

```json
{
  "token": "jwt-token-here"
}
```

- JWT expiration is currently configured as `1296000000` ms, which is 15 days.
- Passwords must be at least 8 characters.
- OTPs are 6 digits, expire after 5 minutes, and have a 30 second resend cooldown.
- `test@gmail.com` is treated as a test account email. Its verification OTP is always `123456`.
- During development, OTP emails are also printed in the Spring Boot terminal:

```text
DEV OTP for user@example.com: 123456
```

Remove that logging before production.

## Recommended Flutter Auth Flow

1. Register with `POST /auth/register`.
2. Show OTP screen.
3. Verify email with `POST /auth/verify`.
4. Log in with `POST /auth/login`.
5. Store the returned JWT securely.
6. Send `Authorization: Bearer <token>` on protected API calls.
7. If the backend returns `401`, clear the token and send the user back to login.

Use `flutter_secure_storage` or another secure storage package for the JWT. Do not store the token in plain shared preferences.

## Endpoint Summary

| Method | Endpoint | Auth Required | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/register` | No | Create account and send email OTP |
| POST | `/auth/verify` | No | Verify registration OTP |
| POST | `/auth/resend-verification` | No | Resend email verification OTP |
| POST | `/auth/login` | No | Login and receive JWT |
| POST | `/auth/forgot-password` | No | Send password reset OTP |
| POST | `/auth/reset-password` | No | Reset password using OTP |
| POST | `/auth/change-password` | Yes | Change password for logged-in user |
| GET | `/auth/hello` | Yes | Test that JWT is valid |
| GET | `/oauth2/authorization/google` | No | Start Google OAuth login in browser |
| GET | `/auth/google` | OAuth session | Google OAuth success endpoint returning JWT |

## 1. Register

Creates an unverified user and sends an OTP to the email address.

```http
POST /auth/register
```

Request:

```json
{
  "username": "pratyush",
  "email": "user@example.com",
  "password": "password123",
  "profilePic": "https://example.com/avatar.png"
}
```

Notes:

- `profilePic` is optional.
- Backend also accepts `userName` as an alias for `username`.
- Email is lowercased and trimmed by the backend.
- Usernames must be unique.
- Emails must be unique.

Success response:

```text
User registered successfully! Check your email for OTP.
```

Test email success response:

```text
Test user registered successfully! Use OTP 123456 to verify.
```

Common error responses:

```text
Username is required
Valid email is required
Password must be at least 8 characters long
Username is already taken!
Email is already taken!
Username or email is already taken!
Too many requests. Please try again later.
Verification service is temporarily unavailable.
```

Example curl:

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"pratyush\",\"email\":\"user@example.com\",\"password\":\"password123\",\"profilePic\":\"https://example.com/avatar.png\"}"
```

## 2. Verify Email OTP

Verifies the OTP sent during registration or resend verification.

```http
POST /auth/verify
```

Request:

```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

Success response:

```text
Email verified successfully!
```

Common error responses:

```text
Valid email is required
Invalid or expired OTP!
Too many requests. Please try again later.
Verification service is temporarily unavailable.
```

Flutter behavior:

- If success, navigate to login or log in automatically if you also have the password locally.
- If `Invalid or expired OTP!`, let the user retry or resend.
- If rate limited, show a retry later message.

## 3. Resend Verification OTP

Requests another email verification OTP for an unverified user.

```http
POST /auth/resend-verification
```

Request:

```json
{
  "email": "user@example.com"
}
```

The backend DTO also has `otp`, but this endpoint ignores it. Do not send `otp` from Flutter.

Success response:

```text
If an account exists, we've sent a verification email.
```

The backend intentionally returns the same message even if the account does not exist, is already verified, or is a test account.

Common error responses:

```text
Valid email is required
Too many requests. Please try again later.
Verification service is temporarily unavailable.
Please wait 30 seconds before requesting another OTP.
```

## 4. Login

Logs in a verified user and returns a JWT.

```http
POST /auth/login
```

Request:

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Success response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

Common error responses:

```text
Invalid credentials
Email is not verified
```

Status codes:

- `200`: Login successful.
- `401`: Invalid credentials or email not verified.

Flutter behavior:

- Save `token` in secure storage.
- Add it to all protected calls as `Authorization: Bearer <token>`.
- If response is `Email is not verified`, route the user to OTP verification or resend screen.

## 5. Forgot Password

Sends a password reset OTP to a verified non-test user.

```http
POST /auth/forgot-password
```

Request:

```json
{
  "email": "user@example.com"
}
```

Success response:

```text
If an account exists, we've sent a password reset email.
```

The backend intentionally returns the same message even when the account does not exist or is not eligible.

Common error responses:

```text
Valid email is required
Too many requests. Please try again later.
Password reset service is temporarily unavailable.
Please wait 30 seconds before requesting another OTP.
```

## 6. Reset Password

Uses the reset OTP to set a new password.

```http
POST /auth/reset-password
```

Request:

```json
{
  "email": "user@example.com",
  "otp": "123456",
  "newPassword": "newpassword123",
  "confirmPassword": "newpassword123"
}
```

Success response:

```text
Password reset successfully.
```

Common error responses:

```text
Valid email is required
Password must be at least 8 characters long
Passwords do not match
Invalid or expired OTP!
Too many requests. Please try again later.
Password reset service is temporarily unavailable.
```

## 7. Change Password

Changes password for the currently logged-in user. This endpoint requires a JWT.

```http
POST /auth/change-password
Authorization: Bearer <jwt_token>
```

Request:

```json
{
  "oldPassword": "password123",
  "newPassword": "newpassword123",
  "confirmPassword": "newpassword123"
}
```

Success response:

```text
Password changed successfully.
```

Common error responses:

```text
Authentication required
Old password is required
Password must be at least 8 characters long
Passwords do not match
Invalid credentials
```

Status codes:

- `200`: Password changed.
- `400`: Invalid input.
- `401`: Missing token, invalid token, or wrong old password.

## 8. Validate Token Test Endpoint

This is useful during integration to confirm the stored token works.

```http
GET /auth/hello
Authorization: Bearer <jwt_token>
```

Success response:

```text
Hello, <user-id>! Your token is valid.
```

The JWT subject is the backend user id, so `<user-id>` is not the email.

## 9. Google OAuth

Current backend routes:

```http
GET /oauth2/authorization/google
GET /auth/google
```

Integration notes:

- Start Google login by opening `/oauth2/authorization/google` in an external browser or web view.
- After Google OAuth succeeds, Spring redirects to `/auth/google`.
- `/auth/google` creates or finds the user, marks the account verified, and returns:

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

Important for Flutter:

- Do not call `/auth/google` directly without completing the OAuth flow. It will return `No principal found`.
- The current backend returns the token as a normal HTTP JSON response from `/auth/google`.
- A mobile-friendly redirect or deep link callback is not currently implemented. If the app needs native Google sign-in, the backend should add a dedicated endpoint that accepts a Google ID token from Flutter and returns this app's JWT.

## Flutter DTOs

Minimal models:

```dart
class AuthResponse {
  final String token;

  AuthResponse({required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(token: json['token'] as String);
  }
}

class ApiResult<T> {
  final T? data;
  final String? message;
  final int statusCode;

  ApiResult({this.data, this.message, required this.statusCode});

  bool get ok => statusCode >= 200 && statusCode < 300;
}
```

## Flutter Example Using Dio

Recommended packages:

```yaml
dependencies:
  dio: ^5.0.0
  flutter_secure_storage: ^9.0.0
```

Auth API client:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthApi {
  AuthApi(String baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ));

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> get token => _storage.read(key: 'auth_token');

  Future<Response<dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? profilePic,
  }) {
    return _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
      if (profilePic != null) 'profilePic': profilePic,
    });
  }

  Future<Response<dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) {
    return _dio.post('/auth/verify', data: {
      'email': email,
      'otp': otp,
    });
  }

  Future<Response<dynamic>> resendVerification({required String email}) {
    return _dio.post('/auth/resend-verification', data: {
      'email': email,
    });
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final token = response.data['token'] as String;
      await _storage.write(key: 'auth_token', value: token);
      return token;
    }

    throw Exception(response.data?.toString() ?? 'Login failed');
  }

  Future<Response<dynamic>> forgotPassword({required String email}) {
    return _dio.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  Future<Response<dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _dio.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  Future<Response<dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final savedToken = await token;
    return _dio.post(
      '/auth/change-password',
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      options: Options(headers: {
        'Authorization': 'Bearer $savedToken',
      }),
    );
  }

  Future<Response<dynamic>> hello() async {
    final savedToken = await token;
    return _dio.get(
      '/auth/hello',
      options: Options(headers: {
        'Authorization': 'Bearer $savedToken',
      }),
    );
  }

  Future<void> logout() {
    return _storage.delete(key: 'auth_token');
  }
}
```

## Handling Responses in Flutter

Because most endpoints return plain text, the UI can display `response.data.toString()` for non-JSON responses.

Example:

```dart
final response = await authApi.register(
  username: 'pratyush',
  email: 'user@example.com',
  password: 'password123',
);

if (response.statusCode == 200) {
  // Navigate to OTP screen.
} else {
  final message = response.data?.toString() ?? 'Something went wrong';
  // Show message in snackbar/dialog/form error.
}
```

For login, parse JSON and store the token.

## Rate Limits and OTP Rules

Registration:

- 3 attempts per device per minute.
- 10 attempts per device per hour.
- 3 attempts per email per hour for non-test emails.

Verification, resend verification, forgot password, and reset password:

- 10 attempts per device per minute.
- 5 attempts per email per minute.

OTP:

- 6 digit numeric code.
- Valid for 5 minutes.
- Resend cooldown is 30 seconds.
- Used OTP is deleted after successful verification.

## Status Code Handling

Handle these status codes globally:

| Status | Meaning | Flutter behavior |
| --- | --- | --- |
| 200 | Success | Continue flow |
| 400 | Invalid input or invalid OTP | Show returned message |
| 401 | Not authenticated or bad credentials | Clear token and route to login if protected call |
| 429 | Rate limited | Show returned message and block immediate retry |
| 503 | Redis verification service unavailable | Show temporary service error |

## Integration Checklist

- Configure the correct base URL for emulator, simulator, physical device, and production.
- Send `Content-Type: application/json`.
- Implement register, OTP verify, resend OTP, login, forgot password, reset password, change password.
- Store JWT using secure storage.
- Attach `Authorization: Bearer <token>` to protected requests.
- Route `401` responses back to login.
- Display backend plain text error messages directly or map them to friendly UI copy.
- Add a 30 second resend OTP timer in the UI.
- Use `test@gmail.com` with OTP `123456` for quick local verification testing.
- During development, read real OTPs from the Spring Boot terminal log line.
