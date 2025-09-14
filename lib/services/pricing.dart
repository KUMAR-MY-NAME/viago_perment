class Pricing {
  static const double _platformFeePercentage = 0.10; // 10% platform fee

  static double volumetricWeightKg({
    required double lCm,
    required double wCm,
    required double hCm,
  }) {
    return (lCm * wCm * hCm) / 5000.0;
  }

  static double estimate({
    required double minCharge,
    required double baseFare,
    required double perKm,
    required double distanceKm,
    required double perKg,
    required double actualWeightKg,
    required double lCm,
    required double wCm,
    required double hCm,
    bool fragile = false,
    bool fast = false,
  }) {
    final billable =
        (actualWeightKg > volumetricWeightKg(lCm: lCm, wCm: wCm, hCm: hCm))
            ? actualWeightKg
            : volumetricWeightKg(lCm: lCm, wCm: wCm, hCm: hCm);

    double extras = 0;
    if (fragile) extras += 49;
    if (fast) extras += 79;

    final raw = baseFare + (perKm * distanceKm) + (perKg * billable) + extras;
    final basePrice = raw < minCharge ? minCharge : double.parse(raw.toStringAsFixed(2));

    // Calculate platform fee
    final platformFee = basePrice * _platformFeePercentage;

    // Total price includes platform fee
    return double.parse((basePrice + platformFee).toStringAsFixed(2));
  }

  // New method to get just the platform fee for a given base price
  static double getPlatformFee(double basePrice) {
    return double.parse((basePrice * _platformFeePercentage).toStringAsFixed(2));
  }

  // New method to get the amount the traveler receives
  static double getTravelerEarning(double totalPackagePrice) {
    return double.parse((totalPackagePrice * (1 - _platformFeePercentage)).toStringAsFixed(2));
  }
}