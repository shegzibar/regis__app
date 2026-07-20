import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('settings.terms_and_conditions'.tr()),
        backgroundColor: AppColors.darkCard,
        elevation: 0,
      ),
      body: Markdown(
        data: _termsContent,
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          p: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          listBullet: const TextStyle(color: Colors.white70),
          strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          tableBody: const TextStyle(color: Colors.white70),
          tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          tableBorder: TableBorder.all(color: AppColors.darkBorder),
        ),
      ),
    );
  }

  static const String _termsContent = '''
# GamingHub Terms & Conditions

**Last Updated:** January 2025

---

## 1. Agreement to Terms

By downloading, accessing, and using the GamingHub app and website (the "Service"), you agree to be bound by these Terms & Conditions. If you do not agree to these terms, you may not use the Service.

GamingHub reserves the right to modify these terms at any time. Changes will be posted in the app, and your continued use means you accept the new terms.

---

## 2. Use License

GamingHub grants you a limited, non-exclusive, non-transferable license to download and use the Service for personal, non-commercial use. You may not:
- Modify, copy, or distribute the app or its content
- Reverse engineer or attempt to access its source code
- Use the Service for illegal purposes
- Interfere with other users' experience
- Create fake accounts or impersonate others
- Spam or harass other users
- Attempt to gain unauthorized access to the Service

---

## 3. Intellectual Property Rights

All content in GamingHub (logos, text, graphics, code) is the property of GamingHub or our content providers. You may not reproduce, modify, or distribute this content without permission.

Gaming center photos uploaded by owners remain their property, but by uploading them, owners grant GamingHub permission to display and use them within the app.

---

## 4. User Accounts

### Account Responsibility
- You are responsible for maintaining your password's confidentiality
- You are responsible for all activities under your account
- You agree to provide accurate information during registration
- You agree to keep your information up-to-date

### Account Suspension
We may suspend or delete your account if you:
- Violate these terms
- Engage in illegal activity
- Harass or abuse other users
- Violate our community guidelines
- Use fake information

---

## 5. Booking & Reservations

### Booking Process
- Bookings are confirmed once payment is received
- You must complete bookings by the reserved time or forfeit your spot
- Cancellations must be made according to the gaming center's policy
- No-shows may result in wallet point deduction or account restrictions

### Payment
- You agree to pay the stated booking fee (5-10 EGP depending on the gaming center)
- You may pay with wallet points, cash, or other accepted payment methods
- Prices are subject to change without notice

### Refunds
- Refund policies are determined by individual gaming centers
- Contact the gaming center directly for refund requests
- GamingHub is not responsible for refund disputes between users and gaming centers

---

## 6. Wallet System

### Points
- 1 wallet point = 1 EGP value
- Points are earned from completed gaming sessions
- Points are credited after your session ends
- Points do not expire

### Top-Ups
- You may purchase points by paying cash at any gaming center
- Top-ups are instant and irreversible
- GamingHub is not responsible for lost or stolen wallet access

### Prohibited Activities
- You may not buy, sell, or trade points with other users
- You may not attempt to manipulate or hack the wallet system
- Any fraudulent activity may result in account termination

---

## 7. Reviews & Ratings

### Content Guidelines
You agree that reviews and ratings will:
- Be honest and truthful
- Not contain personal attacks or harassment
- Not include inappropriate language or content
- Not violate anyone's privacy or intellectual property
- Be based on actual experience with the gaming center

### Moderation
GamingHub reserves the right to:
- Remove inappropriate reviews
- Hide reviews that violate these terms
- Suspend accounts of users who repeatedly post harmful content

---

## 8. Limitation of Liability

**THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES.**

GamingHub is not responsible for:
- Interruptions or errors in the Service
- Loss of data or wallet points (except in case of our direct negligence)
- Disputes between users and gaming centers
- Injuries or damages at gaming centers
- Booking cancellations or changes by gaming centers
- Inaccurate information provided by gaming centers

To the maximum extent allowed by law, GamingHub is not liable for any indirect, incidental, special, or consequential damages.

---

## 9. Disclaimer

- GamingHub does not operate or manage the gaming centers. Gaming centers are independent businesses.
- Gaming center information (hours, pricing, rules) may change without notice.
- GamingHub is not responsible for gaming center policies or conduct.
- Safe use of gaming facilities is the responsibility of both the gaming center and the user.

---

## 10. User Conduct

You agree not to:
- Post offensive, abusive, or hateful content
- Threaten, harass, or discriminate against other users
- Impersonate others
- Post explicit sexual content
- Spam or send unsolicited messages
- Engage in money laundering or fraud
- Violate any laws or regulations
- Help others violate these terms

Violations may result in account suspension or termination without refund.

---

## 11. Disputes with Gaming Centers

### GamingHub's Role
- GamingHub facilitates bookings but does not operate gaming centers
- Disputes between users and gaming centers should be resolved directly
- GamingHub may mediate if requested, but has no obligation to do so

### Resolution Process
1. Contact the gaming center directly
2. If unresolved, contact GamingHub support: support@gaminghub.app
3. Provide details and evidence of the dispute
4. GamingHub will review and respond within 7 days

---

## 12. Prohibited Activities

You may not:
- Use bots or automation tools
- Scrape or copy data from the app
- Attempt to access other users' accounts
- Engage in price manipulation or fraud
- Use the Service for commercial purposes without permission
- Create multiple accounts to manipulate bookings or reviews

---

## 13. Gaming Center Operators

### Your Responsibilities
- Provide accurate information about your gaming center
- Keep your profile updated
- Respond professionally to users
- Follow all local laws and regulations
- Maintain safe and clean facilities
- Honor confirmed bookings

### Prohibited Activities
- Discrimination based on age, gender, race, religion, or other protected characteristics
- Misleading or false information
- Overcharging users
- Harassment or abuse of users

---

## 14. Age Requirements

- Users must be at least 18 years old to use GamingHub
- Users under 18 may require parental consent to book at gaming centers (determined by local law and gaming center policy)
- GamingHub is not responsible for enforcing age restrictions

---

## 15. Payment & Refunds

### Payment
- All payments must be made through approved methods
- Prices are displayed before booking confirmation
- You agree to pay the stated amount

### Refunds
- Refund requests must be made within 30 days of the transaction
- Refunds are processed within 7-14 business days
- Refunds are at GamingHub's discretion based on the circumstances

---

## 16. Indemnification

You agree to defend, indemnify, and hold harmless GamingHub and its officers, directors, employees, and agents from any claims, damages, losses, or expenses arising from:
- Your violation of these terms
- Your use of the Service
- Your disputes with gaming centers
- Your violations of laws or rights of others

---

## 17. Termination

GamingHub may terminate your account immediately if you:
- Violate these terms
- Engage in fraudulent activity
- Harass or abuse others
- Violate laws
- Are inactive for 2 years

Upon termination:
- Your access to the Service stops
- Any remaining wallet points may be forfeited
- You must stop using GamingHub's content and services

---

## 18. Privacy

Your use of GamingHub is governed by our Privacy Policy. Please read it carefully.

---

## 19. Third-Party Links

GamingHub may contain links to third-party websites and services. We are not responsible for their content, privacy practices, or availability. Use them at your own risk.

---

## 20. Governing Law

These Terms & Conditions are governed by the laws of Egypt. Any disputes will be resolved in the courts of Egypt.

---

## 21. Severability

If any provision of these terms is found to be invalid or unenforceable, that provision will be removed, and the remaining provisions will remain in effect.

---

## 22. Entire Agreement

These Terms & Conditions, along with our Privacy Policy, constitute the entire agreement between you and GamingHub regarding your use of the Service.

---

## 23. Contact Us

**Questions or Concerns About These Terms?**

Email: support@gaminghub.app

**Mailing Address:**
GamingHub
Cairo, Egypt

---

## 24. Quick Summary

| Topic | Rule |
|---|---|
| Account | You're responsible for your account; don't share your password |
| Bookings | Complete bookings on time; refund policy depends on gaming center |
| Wallet Points | 1 point = 1 EGP; points don't expire; no trading points with others |
| Reviews | Be honest; don't harass; offensive reviews will be removed |
| Conduct | No harassment, fraud, spam, or illegal activity |
| Gaming Centers | Independent businesses; GamingHub doesn't operate them |
| Disputes | Contact the gaming center first; GamingHub can mediate |
| Age | Must be 18+ to use; local age requirements for gaming may apply |
| Termination | We can terminate your account if you violate these terms |

---

**By using GamingHub, you acknowledge that you have read and agreed to these Terms & Conditions.**
''';
}
