import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/client_entity.dart';
import '../../providers/client_provider.dart';
import '../../widgets/clients/add_edit_client_sheet.dart';
import '../../widgets/loading/shimmer_widgets.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);
const _kAmber = Color(0xFFF59E0B);

class ClientDirectoryScreen extends ConsumerStatefulWidget {
  const ClientDirectoryScreen({super.key});

  @override
  ConsumerState<ClientDirectoryScreen> createState() =>
      _ClientDirectoryScreenState();
}

class _ClientDirectoryScreenState extends ConsumerState<ClientDirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddClientSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddEditClientSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            _Header(onAdd: _showAddClientSheet),

            // ── Search Bar ───────────────────────────────────────────────────
            _SearchBar(
              controller: _searchController,
              onChanged: (v) => ref.read(clientProvider.notifier).search(v),
            ),

            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: clientState.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: 4,
                      itemBuilder: (_, __) => const ClientCardShimmer(),
                    )
                  : clientState.allClients.isEmpty && !clientState.isLoading
                  ? const _EmptyState(hasSearch: false)
                  : clientState.filteredClients.isEmpty
                  ? const _EmptyState(hasSearch: true)
                  : _ClientList(groupedClients: clientState.groupedClients),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Clients',
            style: GoogleFonts.publicSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: _kOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66FF6B35),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final hasText = widget.controller.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: GoogleFonts.publicSans(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search by name, trade or project...',
            hintStyle: GoogleFonts.publicSans(color: _kMuted, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _kMuted,
              size: 20,
            ),
            suffixIcon: _hasText
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _kMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}

// ─── Grouped Client List ──────────────────────────────────────────────────────

class _ClientList extends StatelessWidget {
  final Map<String, List<ClientEntity>> groupedClients;
  const _ClientList({required this.groupedClients});

  @override
  Widget build(BuildContext context) {
    final keys = groupedClients.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final letter = keys[index];
        final clients = groupedClients[letter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 2,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    letter,
                    style: GoogleFonts.publicSans(
                      color: _kOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Client Cards
            ...clients.map((client) => _ClientCard(client: client)),
          ],
        );
      },
    );
  }
}

// ─── Client Card ──────────────────────────────────────────────────────────────

class _ClientCard extends ConsumerWidget {
  final ClientEntity client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = client.name.length >= 2
        ? client.name.substring(0, 2).toUpperCase()
        : client.name.toUpperCase();

    final currency = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(client.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) async {
                final phone = client.phone;
                if (phone != null && phone.isNotEmpty) {
                  final url = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('No dialer app available.'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  }
                }
              },
              backgroundColor: _kAmber,
              foregroundColor: Colors.white,
              icon: Icons.phone_rounded,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => _onDelete(context, ref),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => context.push('/client-detail/${client.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kAmber, Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.publicSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Client Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: GoogleFonts.publicSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.address ?? 'No address provided',
                        style: GoogleFonts.publicSans(
                          color: _kMuted,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Stats Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _kOrange.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${client.totalQuotes} QUOTES',
                              style: GoogleFonts.jetBrainsMono(
                                color: _kOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${currency.format(client.totalValue)} TOTAL',
                            style: GoogleFonts.jetBrainsMono(
                              color: _kMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _kMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(clientProvider.notifier);
    final count = await notifier.getClientQuoteCount(client.id);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kSurface,
        title: Text(
          'Delete Client?',
          style: GoogleFonts.publicSans(color: Colors.white),
        ),
        content: Text(
          count > 0
              ? 'This client has $count quotes. Deleting will NOT delete their quotes. Continue?'
              : 'Are you sure you want to delete this client?',
          style: GoogleFonts.publicSans(color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.deleteClient(client.id);
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kSurface,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder, width: 2),
              ),
              child: Icon(
                hasSearch
                    ? Icons.person_search_rounded
                    : Icons.contact_page_outlined,
                color: _kMuted,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch ? 'No clients match your search' : 'No clients yet',
              style: GoogleFonts.publicSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch
                  ? 'Try searching for something else'
                  : 'Clients are automatically added when you save a quote.',
              style: GoogleFonts.publicSans(color: _kMuted, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ShimmerList removed in favor of ClientCardShimmer
