class DeveloperAdNotificationSample {
  const DeveloperAdNotificationSample({
    required this.id,
    required this.labelKey,
    required this.title,
    required this.text,
    required this.notificationId,
  });

  final String id;
  final String labelKey;
  final String title;
  final String text;
  final int notificationId;
}

const developerAdNotificationSamples = [
  DeveloperAdNotificationSample(
    id: 'flash_sale',
    labelKey: 'Dev ad: Flash sale',
    title: 'Flash sale ends in 2 hours',
    text: '90% off selected items. Tap now before it is gone!',
    notificationId: 9101,
  ),
  DeveloperAdNotificationSample(
    id: 'coupon',
    labelKey: 'Dev ad: Coupon',
    title: 'Exclusive coupon inside',
    text: 'Claim your 50% off deal. Limited time offer for you.',
    notificationId: 9102,
  ),
  DeveloperAdNotificationSample(
    id: 'loan',
    labelKey: 'Dev ad: Loan promo',
    title: 'Pre-approved loan available',
    text: 'You qualify for a low-rate loan. Apply today with one tap.',
    notificationId: 9103,
  ),
  DeveloperAdNotificationSample(
    id: 'free_gift',
    labelKey: 'Dev ad: Free gift',
    title: 'FREE REWARDS waiting',
    text: 'Install now and get 500 coins free. Do not miss out!!!',
    notificationId: 9104,
  ),
  DeveloperAdNotificationSample(
    id: 'security_phish',
    labelKey: 'Dev ad: Security alert',
    title: 'Account security alert',
    text: 'Unusual login detected. Verify your identity immediately.',
    notificationId: 9105,
  ),
  DeveloperAdNotificationSample(
    id: 'delivery_scam',
    labelKey: 'Dev ad: Delivery notice',
    title: 'Package delivery failed',
    text: 'Your parcel is held at the warehouse. Pay a redelivery fee now.',
    notificationId: 9106,
  ),
];
