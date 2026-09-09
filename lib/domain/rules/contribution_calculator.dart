class ContributionCalculator {
  const ContributionCalculator();

  double totalPot({required double contribution, required int memberCount}) {
    if (contribution <= 0 || memberCount <= 0) {
      throw ArgumentError('Les valeurs doivent être positives.');
    }
    return contribution * memberCount;
  }
}