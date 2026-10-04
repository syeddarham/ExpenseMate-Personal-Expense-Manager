ExpenseMate --- Personal Expense Manager

1. Project Description

ExpenseMate is a personal expense management application designed to
help individuals track income and expenses, manage budgets, monitor
financial activity, and understand spending patterns through clear
visual analytics.

The project is based on a UI/UX design created in Figma and will be
implemented as a full-stack application using Flutter for the client
application, Node.js with Express for the backend REST API, and
MySQL for persistent data storage.

The system follows a Client-Server architecture. Flutter acts as the
client, communicating with the Node.js/Express backend through HTTP/REST
APIs. The backend handles authentication, validation, business logic,
and database operations through MySQL.

System Architecture

Flutter
   │
   │ HTTP / REST API
   ▼
Node.js / Express
   │
   │ MySQL driver
   ▼
MySQL

2. Target Audience and Value Proposition

Target Users

ExpenseMate is intended for:

Students

Young professionals

Individuals managing personal finances

Household budgeters

Users who want a simple way to monitor their spending

Value Proposition

ExpenseMate reduces the effort required to record financial transactions
and provides clear visual feedback about income, expenses, budgets, and
spending patterns. The application is intended to help users reduce
spending guesswork and improve awareness of their financial habits.

3. Key Modules and Features

3.1 Overview & Dashboard

The dashboard provides users with an overview of their current financial
situation.

Total Balance Summary --- Displays the overall balance across
available financial sources such as cash, bank accounts, credit
cards, and digital wallets.

Financial Flow --- Displays income and expenses for the selected
period.

Recent Activity --- Shows recent transactions with category
icons, dates/timestamps, and merchant or source information.

Quick Actions --- Provides shortcuts for adding transactions,
transfers, and viewing reports.

3.2 Expense & Income Logging

The transaction module allows users to quickly record financial
activity.

Quick-add transaction interface

Income and expense entry

Predefined and customizable categories

Payment source/account selection

Transaction date

Notes and tags

Optional receipt attachments

Example categories include:

Food & Dining

Groceries

Transport

Bills & Utilities

Entertainment

Health

3.3 Budget Management

The budgeting module allows users to control spending limits.

Monthly overall budgets

Category-specific spending limits

Visual budget progress indicators

Budget consumption percentages

Budget status notifications

Alerts when spending approaches or exceeds a defined limit

3.4 Analytics & Financial Insights

The analytics module provides visual representations of financial
activity.

Category-wise expense breakdown

Pie charts for spending distribution

Line/bar charts for historical trends

Daily, weekly, monthly, and yearly filters

Identification of major spending categories

3.5 Accounts & Settings

The account and settings module manages financial sources and
application preferences.

Cash, bank, card, and digital-wallet accounts

Account balance management

User profile management

Light and dark themes

Currency settings

Security options such as biometric lock

Data export options such as CSV/PDF

4. Design & UI/UX

The Figma design follows a reusable design-system approach.

Design System

The interface uses:

Consistent typography scales

Financial color conventions

Reusable buttons, cards, navigation bars, and modals

Consistent iconography

Standardized spacing and layout rules

Income and expense information uses distinct visual treatment to make
financial information easy to understand.

Responsive Design

Figma Auto-Layout is used to support different screen sizes and layouts,
including mobile and tablet viewports.

Navigation

The primary navigation is organized around the main functions of the
application:

Home
Analytics
Add (+)
Budget
Profile

This provides direct access to the dashboard, financial insights,
transaction creation, budget management, and user settings.

Figma Project Screen Inventory (20 Screens):
- 01_SplashScreen: App launch branding & tagline
- 02_Onboarding: Welcome hero, value proposition, TOS agreement
- 03_Auth: Welcome gateway, Sign In button, Social login (Google/Apple/Facebook)
- 04_Sign in: Sign In with email, password, remember me, forgot password
- 05_Sign in Filled: Filled & validated sign-in state
- 06_Sign up: Account registration with full name, email, passwords, TOS check
- 07_Sign up Filled: Filled & validated sign-up state
- 08_Email Verification: 6-digit OTP entry, resend timer
- 09_Email Verification Filled: Filled verification OTP state
- 10_Forgot Password: Email submission for password reset link
- 11_Reset Password Empty: Password creation with strength rules
- 12_Reset Password Filled: Filled new password state
- 13_Password Reset Success: Confirmation of password change
- 14_Citizenship: Country of residence selection
- 15_Select Currency: Base currency configuration (USD, EUR, GBP, BDT, INR)
- 16_HomeScreen: Balance card ($87,453.43), quick recipients, recent activity
- 17_HomeScreen-Extended: Monthly spending charts, savings distribution, historical trends
- 18_Transactions Screen: Multi-account balance cards, transaction log with +/- indicators
- 19_Scan Screen: Receipt / QR code camera scanning viewfinder (QR / Expense / Bill)
- 20_Add Transaction Screen: Quick transaction entry (amount, category, wallet, note, receipt)


5. Technology Stack

Layer               Technology

Frontend / Client   Flutter
Backend / Server    Node.js + Express
Database            MySQL
Communication       HTTP / REST API
Database Access     MySQL Driver or ORM
Frontend Testing    Flutter / Dart Testing
Backend Testing     Node.js Testing Framework

Responsibilities by Layer

Flutter

Provides the user interface.

Handles screen navigation and user interactions.

Sends requests to the backend.

Displays data returned by the API.

Maintains reusable UI components and client-side models.

Node.js / Express

Provides REST API endpoints.

Handles authentication and authorization.

Validates incoming requests.

Implements application/business logic.

Performs database operations.

Returns structured responses to the Flutter client.

MySQL

Stores persistent application data.

Maintains relational data such as users, transactions, categories,
accounts, and budgets.

Provides structured and reliable database storage.

6. Flutter Project Structure

The Flutter application is organized into pages, reusable components,
services, models, utilities, assets, and tests.

my_app/
│
├── lib/
│   ├── main.dart
│   │
│   ├── app.dart
│   │
│   ├── pages/
│   │   ├── home/
│   │   │   └── home_page.dart
│   │   │
│   │   ├── login/
│   │   │   └── login_page.dart
│   │   │
│   │   └── profile/
│   │       └── profile_page.dart
│   │
│   ├── components/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── app_bar.dart
│   │   └── loading.dart
│   │
│   ├── services/
│   │   ├── api_service.dart
│   │   └── auth_service.dart
│   │
│   ├── models/
│   │   ├── user.dart
│   │   └── product.dart
│   │
│   └── utils/
│       ├── constants.dart
│       └── helpers.dart
│
├── assets/
│   ├── images/
│   └── icons/
│
├── android/
├── ios/
├── web/
├── test/
│
├── pubspec.yaml
└── README.md

Note: product.dart is currently part of the starter structure
and will be replaced or adapted to represent an ExpenseMate domain
entity when the final data model is defined.

Directory Responsibilities

Directory           Responsibility

lib/main.dart     Application entry point
lib/app.dart      Global app configuration, theme, and routing
lib/pages/        Application screens
lib/components/   Reusable UI components
lib/services/     API and application services
lib/models/       Dart data models
lib/utils/        Constants and helper functions
assets/           Images and icons
test/             Automated Flutter/Dart tests

7. Backend Communication Flow

The application uses a layered request flow between the user interface
and database.

User Action
    │
    ▼
Flutter Page
    │
    ▼
Flutter Service
    │
    │ HTTP Request
    ▼
Node.js / Express API
    │
    ▼
Validation & Business Logic
    │
    │ SQL / ORM
    ▼
 MySQL
    │
    ▼
Node.js / Express
    │
    │ HTTP Response
    ▼
Flutter Service
    │
    ▼
Flutter UI

This separation keeps presentation, business logic, and data storage
responsibilities independent, making the application easier to test,
maintain, and extend.

8. Project Scope

The initial system is expected to provide:

User authentication

Income recording

Expense recording

Expense categorization

Account/payment-source management

Monthly budget management

Budget alerts

Category-wise analytics

Visual spending charts

Transaction history

CSV/PDF data export

User profile and application settings

Potential future enhancements include:

Multi-currency support

Cloud backup

Additional financial accounts and integrations

Expanded reporting features

9. Development Approach

The project will follow the Software Construction lifecycle required by
the assignment:

Requirements
     ↓
System Design
     ↓
Architecture & Planning
     ↓
Construction
     ↓
Unit Testing
     ↓
Integration Testing
     ↓
System Testing
     ↓
Maintenance & Evolution

The implementation will be developed as separate frontend, backend, and
database components while maintaining clear interfaces between each
layer.

10. Project Objective

The primary objective of ExpenseMate is to build a small but complete
personal finance management system that demonstrates practical Software
Construction concepts, including:

Requirements analysis

Software architecture

Modular design

Frontend and backend development

Database integration

Unit and integration testing

System testing

Code quality and complexity measurement

Bug tracking and fixing

Refactoring

Maintenance and future evolution