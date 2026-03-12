import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/templates/job_materials_template.dart';
import '../../data/local/database.dart';
import '../../data/repositories/quote_repository.dart';
import '../../data/repositories/client_repository.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/entities/client_entity.dart';
import 'package:drift/drift.dart' show Value;

// ─── State ────────────────────────────────────────────────────────────────────

class NewQuoteState {
  // Step 1 fields
  final String? selectedJobType;
  final List<File> photos;
  final String? voiceNotePath;
  final String jobAddress;

  // Step 2 fields
  final String clientName;
  final String? clientPhone;
  final String? clientEmail;
  final List<QuoteItemDraft> items;
  final double laborHours;
  final double laborRate;
  final double taxRate;
  final bool applyTax;
  final String notes;

  // Async state
  final bool isSaving;
  final String? saveError;

  const NewQuoteState({
    this.selectedJobType,
    this.photos = const [],
    this.voiceNotePath,
    this.jobAddress = '',
    this.clientName = '',
    this.clientPhone,
    this.clientEmail,
    this.items = const [],
    this.laborHours = 0.0,
    this.laborRate = 0.0,
    this.taxRate = 8.5,
    this.applyTax = false,
    this.notes = '',
    this.isSaving = false,
    this.saveError,
  });

  // ── Derived calculations ───────────────────────────────────────────────────

  /// Sum of all checked material items
  double get materialSubtotal {
    return items.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  /// Labor cost = hours × rate
  double get laborSubtotal => laborHours * laborRate;

  /// Tax applied only if applyTax is true
  double get taxAmount {
    if (!applyTax) return 0.0;
    return (materialSubtotal + laborSubtotal) * (taxRate / 100);
  }

  double get estimatedTotal => materialSubtotal + laborSubtotal + taxAmount;

  NewQuoteState copyWith({
    String? selectedJobType,
    bool clearJobType = false,
    List<File>? photos,
    String? voiceNotePath,
    bool clearVoiceNote = false,
    String? jobAddress,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    List<QuoteItemDraft>? items,
    double? laborHours,
    double? laborRate,
    double? taxRate,
    bool? applyTax,
    String? notes,
    bool? isSaving,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return NewQuoteState(
      selectedJobType: clearJobType
          ? null
          : (selectedJobType ?? this.selectedJobType),
      photos: photos ?? this.photos,
      voiceNotePath: clearVoiceNote
          ? null
          : (voiceNotePath ?? this.voiceNotePath),
      jobAddress: jobAddress ?? this.jobAddress,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      items: items ?? this.items,
      laborHours: laborHours ?? this.laborHours,
      laborRate: laborRate ?? this.laborRate,
      taxRate: taxRate ?? this.taxRate,
      applyTax: applyTax ?? this.applyTax,
      notes: notes ?? this.notes,
      isSaving: isSaving ?? this.isSaving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NewQuoteNotifier extends StateNotifier<NewQuoteState> {
  final QuoteRepository _quoteRepo;
  final ClientRepository _clientRepo;
  final AppDatabase _db;

  NewQuoteNotifier(this._quoteRepo, this._clientRepo, this._db)
    : super(const NewQuoteState());

  // ── Step 1 Setters ──────────────────────────────────────────────────────────

  void selectJobType(String jobType) {
    final newItems = getMaterialsForJobType(jobType)
        .map((item) => item.copyWith(isChecked: false))
        .toList();
    state = state.copyWith(selectedJobType: jobType, items: newItems);
  }

  void deselectJobType() {
    state = state.copyWith(clearJobType: true, items: const []);
  }

  void addPhoto(File photo) {
    if (state.photos.length >= 5) return;
    state = state.copyWith(photos: [...state.photos, photo]);
  }

  void removePhoto(int index) {
    final updated = List<File>.from(state.photos)..removeAt(index);
    state = state.copyWith(photos: updated);
  }

  void setVoiceNote(String path) {
    state = state.copyWith(voiceNotePath: path);
  }

  void clearVoiceNote() {
    state = state.copyWith(clearVoiceNote: true);
  }

  void setJobAddress(String address) {
    state = state.copyWith(jobAddress: address);
  }

  // ── Step 2 Setters ──────────────────────────────────────────────────────────

  void setClientName(String name) {
    state = state.copyWith(clientName: name);
  }

  void setClientPhone(String? phone) {
    state = state.copyWith(clientPhone: phone);
  }

  void setClientEmail(String? email) {
    state = state.copyWith(clientEmail: email);
  }

  void toggleItemChecked(int index) {
    final updated = List<QuoteItemDraft>.from(state.items);
    updated[index] = updated[index].copyWith(
      isChecked: !updated[index].isChecked,
    );
    state = state.copyWith(items: updated);
  }

  void setItemQuantity(int index, int quantity) {
    if (quantity < 1) return;
    final updated = List<QuoteItemDraft>.from(state.items);
    updated[index] = updated[index].copyWith(quantity: quantity);
    state = state.copyWith(items: updated);
  }

  void addCustomItem(String name, double price) {
    final newItem = QuoteItemDraft(
      name: name,
      unitPrice: price,
      isChecked: true,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void setLaborHours(double hours) {
    state = state.copyWith(laborHours: hours.clamp(0, 999));
  }

  void setLaborRate(double rate) {
    state = state.copyWith(laborRate: rate);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }

  void toggleTax() {
    state = state.copyWith(applyTax: !state.applyTax);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  // ── Save Quote ──────────────────────────────────────────────────────────────

  /// Returns null on success, or the quote number so the screen can show
  /// a SnackBar. Returns -1 if blocked by free tier.
  /// The [context] is used only to show the upgrade dialog on free tier block.
  Future<int?> saveQuote(BuildContext context) async {
    // ── 1. Free tier check ─────────────────────────────────────────────────
    final profile = await _db.select(_db.userProfile).getSingleOrNull();
    final plan = profile?.subscriptionPlan ?? 'free';

    if (plan == 'free') {
      final count = await _db
          .customSelect('SELECT COUNT(*) as c FROM quotes')
          .getSingleOrNull();
      final existing = count?.data['c'] as int? ?? 0;
      if (existing >= 5) {
        // Show upgrade dialog — must be done on main isolate
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _UpgradeDialog(),
          );
        }
        return -1; // Blocked
      }
    }

    state = state.copyWith(isSaving: true, clearSaveError: true);

    try {
      // ── 2. Generate IDs ────────────────────────────────────────────────
      const uuid = Uuid();
      final quoteId = uuid.v4();

      // ── 3. Auto-increment quote number from SQLite COUNT ───────────────
      final maxResult = await _db
          .customSelect('SELECT MAX(quote_number) as m FROM quotes')
          .getSingleOrNull();
      final quoteNumber = ((maxResult?.data['m'] as int? ?? 0) + 1);

      // ── 4. Build QuoteEntity ───────────────────────────────────────────
      final now = DateTime.now();
      final checkedItems = state.items.where((i) => i.isChecked).toList();

      final quoteItems = checkedItems
          .mapIndexed(
            (idx, item) => QuoteItemEntity(
              id: uuid.v4(),
              quoteId: quoteId,
              name: item.name,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              isChecked: item.isChecked,
            ),
          )
          .toList();

      // ── 5. Upsert client ────────────────────────────────────────────────
      final clientName = state.clientName.trim();
      final newPhoneRaw = state.clientPhone?.trim();
      final newPhone =
          (newPhoneRaw == null || newPhoneRaw.isEmpty) ? null : newPhoneRaw;
      final newEmailRaw = state.clientEmail?.trim();
      final newEmail =
          (newEmailRaw == null || newEmailRaw.isEmpty) ? null : newEmailRaw;
      final existingClients = await _db.select(_db.clients).get();
      final match = existingClients
          .where((c) => c.name.toLowerCase() == clientName.toLowerCase())
          .firstOrNull;

      String clientId;
      if (match != null) {
        clientId = match.id;
        final shouldUpdatePhone =
            (match.phone == null || match.phone!.isEmpty) && newPhone != null;
        final shouldUpdateEmail =
            (match.email == null || match.email!.isEmpty) && newEmail != null;
        final mergedPhone = shouldUpdatePhone ? newPhone : match.phone;
        final mergedEmail = shouldUpdateEmail ? newEmail : match.email;

        final phoneMismatch = newPhone != null &&
            match.phone != null &&
            match.phone!.isNotEmpty &&
            match.phone != newPhone;
        final emailMismatch = newEmail != null &&
            match.email != null &&
            match.email!.isNotEmpty &&
            match.email != newEmail;

        // Update stats
        await (_db.update(
          _db.clients,
        )..where((c) => c.id.equals(match.id))).write(
          ClientsCompanion(
            totalQuotes: Value(match.totalQuotes + 1),
            totalValue: Value(match.totalValue + state.estimatedTotal),
            phone:
                shouldUpdatePhone ? Value(mergedPhone) : const Value.absent(),
            email:
                shouldUpdateEmail ? Value(mergedEmail) : const Value.absent(),
            isSynced: const Value(false),
          ),
        );
        // Sync updated client to Firestore
        final updatedEntity = ClientEntity(
          id: match.id,
          name: match.name,
          phone: mergedPhone,
          email: mergedEmail,
          address: match.address,
          totalQuotes: match.totalQuotes + 1,
          totalValue: match.totalValue + state.estimatedTotal,
          createdAt: DateTime.fromMillisecondsSinceEpoch(match.createdAt),
        );
        _clientRepo.updateClient(updatedEntity);

        if ((phoneMismatch || emailMismatch) && context.mounted) {
          final parts = <String>[];
          if (phoneMismatch) parts.add('phone');
          if (emailMismatch) parts.add('email');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Client already has a different ${parts.join(' & ')}. Keeping existing.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        clientId = uuid.v4();
        final newClient = ClientEntity(
          id: clientId,
          name: clientName,
          phone: newPhone,
          email: newEmail,
          totalQuotes: 1,
          totalValue: state.estimatedTotal,
          createdAt: now,
        );
        await _clientRepo.createClient(newClient);
      }

      final quoteEntity = QuoteEntity(
        id: quoteId,
        quoteNumber: quoteNumber,
        clientId: clientId,
        clientName: clientName,
        jobType: state.selectedJobType ?? 'General',
        jobAddress: state.jobAddress,
        photosPaths: state.photos.map((f) => f.path).toList(),
        voiceNotePath: state.voiceNotePath,
        notes: state.notes,
        laborHours: state.laborHours,
        laborRate: state.laborRate,
        taxRate: state.taxRate,
        applyTax: state.applyTax,
        status: 'pending',
        totalAmount: state.estimatedTotal,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
        items: quoteItems,
      );

      // ── 6. Save to SQLite + async Firestore ────────────────────────────
      await _quoteRepo.createQuote(quoteEntity);

      state = state.copyWith(isSaving: false);
      return quoteNumber;
    } catch (e) {
      state = state.copyWith(isSaving: false, saveError: e.toString());
      return null;
    }
  }

  /// Reset the entire quote (when user discards or after save)
  void reset() {
    state = const NewQuoteState();
  }
}

// ── Upgrade Dialog ─────────────────────────────────────────────────────────────

class _UpgradeDialog extends StatelessWidget {
  const _UpgradeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upgrade to Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'You\'ve reached the 5-quote limit on the free plan.\n\nUpgrade to Pro for unlimited quotes, client management, and priority support.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Not Now',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Manage Subscription — \$25/mo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final newQuoteProvider = StateNotifierProvider<NewQuoteNotifier, NewQuoteState>(
  (ref) {
    final quoteRepo = ref.watch(quoteRepositoryProvider);
    final clientRepo = ref.watch(clientRepositoryProvider);
    final db = ref.watch(databaseProvider);
    return NewQuoteNotifier(quoteRepo, clientRepo, db);
  },
);

// ── Helper extension ──────────────────────────────────────────────────────────
extension _IndexedMap<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T item) f) sync* {
    var i = 0;
    for (final item in this) {
      yield f(i++, item);
    }
  }
}



