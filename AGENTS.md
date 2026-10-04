# ExpenseMate Development Guidelines & Project Structure

## 1. Project Information
- **Application Name**: ExpenseMate - Personal Expense Manager
- **Domain**: Personal Finance & Expense Management
- **Architecture**: Client-Server Architecture
  - **Frontend / Client**: Flutter (Dart)
  - **Backend / REST API**: Node.js + Express
  - **Database**: PostgreSQL (Driver / ORM)
- **Primary Modules**:
  - Overview & Dashboard (Balance summary, financial flow, recent activity, quick actions)
  - Expense & Income Logging (Transactions, categories, accounts, receipts/tags)
  - Budget Management (Monthly budgets, category limits, visual indicators, alerts)
  - Analytics & Financial Insights (Breakdown charts, trends, time filters)
  - Accounts & Settings (Financial accounts, profile, themes, currency, security, CSV/PDF export)

## 2. Figma UI Design System & 20 Screens Specification
The Figma design file (`KcaQXksBAagWhnB7UMEX1j`) consists of exactly 20 screens that must be implemented in the Flutter frontend:

1. **01_SplashScreen** (`lib/pages/onboarding/splash_page.dart`): App logo, branding ("ExpenseMate", "Track smarter. Spend better.").
2. **02_Onboarding** (`lib/pages/onboarding/onboarding_page.dart`): Hero finance illustration, "Take Control of Your Money", Terms notice, "Next" button.
3. **03_Auth** (`lib/pages/auth/auth_page.dart`): "Welcome to ExpenseMate", "Sign In" button, Social OAuth (Google, Apple, Facebook).
4. **04_Sign in** (`lib/pages/auth/sign_in_page.dart`): "Welcome Back!", Email/Password, Remember Me, Forgot Password, Sign In, Social login, Create Account link.
5. **05_Sign in Filled** (`lib/pages/auth/sign_in_page.dart`): Active input state for Sign in with validated fields.
6. **06_Sign up** (`lib/pages/auth/sign_up_page.dart`): Full Name, Email, Password, Confirm Password, Terms checkbox, Sign Up button.
7. **07_Sign up Filled** (`lib/pages/auth/sign_up_page.dart`): Active validated state for Sign up.
8. **08_Email Verification** (`lib/pages/auth/email_verification_page.dart`): 6-digit OTP boxes, 56s resend timer, "Verify Email" button.
9. **09_Email Verification Filled** (`lib/pages/auth/email_verification_page.dart`): Populated OTP state with active verify button.
10. **10_Forgot Password** (`lib/pages/auth/forgot_password_page.dart`): Email input to receive reset link, "Send Reset Link" button.
11. **11_Reset Password Empty** (`lib/pages/auth/reset_password_page.dart`): New Password, Confirm Password, password strength checklist.
12. **12_Reset Password Filled** (`lib/pages/auth/reset_password_page.dart`): Active filled state for password reset.
13. **13_Password Reset Success** (`lib/pages/auth/password_reset_success_page.dart`): Success checkmark animation, "Password Updated!", "Sign In" button.
14. **14_Citizenship** (`lib/pages/onboarding/citizenship_page.dart`): Country selection list (United States, Singapore, Switzerland, etc.) with checkmarks.
15. **15_Select Currency** (`lib/pages/onboarding/select_currency_page.dart`): Currency selector (USD, EUR, GBP, BDT, INR).
16. **16_HomeScreen** (`lib/pages/home/home_page.dart`): Balance card ($87,453.43), Recent Recipients avatar carousel, Transaction History.
17. **17_HomeScreen-Extended** (`lib/pages/home/home_extended_page.dart`): Monthly Spend chart (-32.3%, $3,545.54), Savings vs Expenses bar chart, Category breakdown.
18. **18_Transactions Screen** (`lib/pages/transaction/transactions_screen.dart`): Multi-card balance carousel ($102,432.43 / $87,453.43), detailed transaction list with +/- indicators.
19. **19_Scan Screen** (`lib/pages/scan/scan_screen.dart`): Receipt / QR code camera scanning viewfinder with tabs (QR, Expense, Bill).
20. **20_Add Transaction Screen** (`lib/pages/transaction/add_transaction_page.dart`): Expense/Income toggle, large amount ($46.80), Category, Wallet, Date, Note, Add Receipt attachment, Save button.

## 3. Standard Flutter Project Structure
When cloning UI screens and components from Figma, **always strictly adhere to the following directory layout**:

```text
lib/
├── main.dart
├── app.dart
├── pages/
│   ├── onboarding/
│   │   ├── splash_page.dart
│   │   ├── onboarding_page.dart
│   │   ├── citizenship_page.dart
│   │   └── select_currency_page.dart
│   ├── auth/
│   │   ├── auth_page.dart
│   │   ├── sign_in_page.dart
│   │   ├── sign_up_page.dart
│   │   ├── email_verification_page.dart
│   │   ├── forgot_password_page.dart
│   │   ├── reset_password_page.dart
│   │   └── password_reset_success_page.dart
│   ├── home/
│   │   ├── home_page.dart
│   │   └── home_extended_page.dart
│   ├── transaction/
│   │   ├── transactions_screen.dart
│   │   └── add_transaction_page.dart
│   ├── scan/
│   │   └── scan_screen.dart
│   ├── budget/
│   │   └── budget_page.dart
│   └── profile/
│       └── profile_page.dart
├── components/
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── app_bar.dart
│   ├── loading.dart
│   ├── transaction_card.dart
│   └── budget_progress_bar.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── expense_state.dart
├── models/
│   ├── user.dart
│   ├── transaction.dart
│   ├── budget.dart
│   └── category.dart
└── utils/
    ├── constants.dart
    └── helpers.dart
```

## 3. Figma UI Cloning Rules
1. **Design System Consistency**:
   - Extract colors, font sizes, paddings, and radii into `lib/utils/constants.dart` or `ThemeData` in `lib/app.dart`.
   - Never hardcode raw hex colors or magic numbers across individual widget files.
2. **Component Reusability**:
   - Reusable Figma elements (buttons, cards, inputs, navigation bars) must be placed in `lib/components/`.
   - Screen-level compositions belong strictly in `lib/pages/<feature>/`.
3. **Clean Architecture**:
   - Keep UI widgets free of direct HTTP logic; delegate network and storage calls to `lib/services/`.
   - Parse payloads using strong typing in `lib/models/`.
