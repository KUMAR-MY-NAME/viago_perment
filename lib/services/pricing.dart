class Pricing {
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
    return raw < minCharge ? minCharge : double.parse(raw.toStringAsFixed(2));
  }
}
