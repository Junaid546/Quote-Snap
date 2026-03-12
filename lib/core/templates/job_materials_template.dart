/// Represents a single line item draft (not yet saved to DB)
class QuoteItemDraft {
  final String name;
  double unitPrice;
  int quantity;
  bool isChecked;

  QuoteItemDraft({
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
    this.isChecked = true,
  });

  QuoteItemDraft copyWith({
    String? name,
    double? unitPrice,
    int? quantity,
    bool? isChecked,
  }) {
    return QuoteItemDraft(
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  double get lineTotal => isChecked ? unitPrice * quantity : 0;
}

/// Returns a default list of materials for a given job type.
List<QuoteItemDraft> getMaterialsForJobType(String jobType) {
  switch (jobType.toLowerCase()) {
    case 'plumbing':
      return [
        QuoteItemDraft(name: 'Copper pipes (10 ft)', unitPrice: 28.50),
        QuoteItemDraft(name: 'Pipe fittings (set)', unitPrice: 15.00),
        QuoteItemDraft(name: 'Solder (1 lb)', unitPrice: 12.99),
        QuoteItemDraft(name: 'Teflon tape', unitPrice: 3.49),
        QuoteItemDraft(name: 'Shut-off valve', unitPrice: 18.75),
        QuoteItemDraft(
          name: 'Plumber\'s putty',
          unitPrice: 6.99,
          isChecked: false,
        ),
      ];
    case 'electrical':
      return [
        QuoteItemDraft(name: 'Wire 12 AWG (50 ft)', unitPrice: 35.00),
        QuoteItemDraft(name: 'Circuit breaker (20A)', unitPrice: 22.50),
        QuoteItemDraft(name: 'Wire nuts (50 pack)', unitPrice: 8.99),
        QuoteItemDraft(name: 'Conduit (10 ft)', unitPrice: 14.00),
        QuoteItemDraft(name: 'Electrical tape', unitPrice: 3.99),
        QuoteItemDraft(name: 'Junction box', unitPrice: 7.49),
      ];
    case 'painting':
      return [
        QuoteItemDraft(name: 'Interior paint (1 gal)', unitPrice: 45.00),
        QuoteItemDraft(name: 'Primer (1 gal)', unitPrice: 28.00),
        QuoteItemDraft(name: 'Paint brushes (set)', unitPrice: 18.99),
        QuoteItemDraft(name: 'Rollers & tray (set)', unitPrice: 14.99),
        QuoteItemDraft(name: "Painter's tape (2 rolls)", unitPrice: 9.49),
        QuoteItemDraft(name: 'Drop cloth', unitPrice: 12.00, isChecked: false),
      ];
    case 'carpentry':
      return [
        QuoteItemDraft(name: '2x4 lumber (8 ft)', unitPrice: 8.50, quantity: 4),
        QuoteItemDraft(name: 'Wood screws (1 lb box)', unitPrice: 11.99),
        QuoteItemDraft(name: 'Sandpaper (assorted)', unitPrice: 9.99),
        QuoteItemDraft(
          name: 'Wood stain (qt)',
          unitPrice: 22.00,
          isChecked: false,
        ),
        QuoteItemDraft(name: 'Wood glue', unitPrice: 7.49),
        QuoteItemDraft(name: 'L-brackets (4 pack)', unitPrice: 12.99),
      ];
    case 'hvac':
      return [
        QuoteItemDraft(
          name: 'Air filter (MERV 11)',
          unitPrice: 24.99,
          quantity: 2,
        ),
        QuoteItemDraft(name: 'Ductwork tape', unitPrice: 14.99),
        QuoteItemDraft(
          name: 'Refrigerant R-410A (lb)',
          unitPrice: 38.00,
          isChecked: false,
        ),
        QuoteItemDraft(
          name: 'Thermostat (smart)',
          unitPrice: 129.00,
          isChecked: false,
        ),
        QuoteItemDraft(name: 'Capacitor', unitPrice: 22.00, isChecked: false),
        QuoteItemDraft(
          name: 'Condensate drain pan',
          unitPrice: 31.00,
          isChecked: false,
        ),
      ];
    case 'windows':
      return [
        QuoteItemDraft(
          name: 'Window caulk (tube)',
          unitPrice: 7.99,
          quantity: 2,
        ),
        QuoteItemDraft(name: 'Weatherstripping (10 ft)', unitPrice: 12.49),
        QuoteItemDraft(
          name: 'Window film (sq ft)',
          unitPrice: 4.00,
          quantity: 10,
          isChecked: false,
        ),
        QuoteItemDraft(
          name: 'Glazing compound',
          unitPrice: 9.99,
          isChecked: false,
        ),
        QuoteItemDraft(name: 'Window lock hardware', unitPrice: 15.00),
      ];
    case 'roofing':
      return [
        QuoteItemDraft(
          name: 'Asphalt shingles (bundle)',
          unitPrice: 45.00,
          quantity: 3,
        ),
        QuoteItemDraft(name: 'Roofing nails (1 lb)', unitPrice: 8.99),
        QuoteItemDraft(name: 'Flashing (10 ft)', unitPrice: 22.00),
        QuoteItemDraft(name: 'Roofing underlayment', unitPrice: 55.00),
        QuoteItemDraft(name: 'Roof sealant', unitPrice: 18.49),
        QuoteItemDraft(
          name: 'Ridge cap shingles (bundle)',
          unitPrice: 50.00,
          isChecked: false,
        ),
      ];
    default: // 'Other' or unrecognized
      return [
        QuoteItemDraft(name: 'Parts & materials', unitPrice: 50.00),
        QuoteItemDraft(name: 'Supplies', unitPrice: 25.00),
        QuoteItemDraft(
          name: 'Miscellaneous',
          unitPrice: 15.00,
          isChecked: false,
        ),
      ];
  }
}
