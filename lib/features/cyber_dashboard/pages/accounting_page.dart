import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking.dart';
import '../constants/cd_colors.dart';
import '../providers/accounting_providers.dart';

class AccountingPage extends ConsumerWidget {
  const AccountingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(accountingPeriodProvider);
    final bookingsAsync = ref.watch(accountingBookingsProvider);
    final summaryAsync = ref.watch(accountingSummaryProvider);
    final isAr = context.locale.languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cyber.accounting'.tr(),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kSidebarText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'cyber.accounting_subtitle'.tr(),
                      style:
                          const TextStyle(fontSize: 13, color: kGray),
                    ),
                  ],
                ),
              ),
              // Period filter
              _PeriodSelector(current: period, isAr: isAr),
            ],
          ),
          const SizedBox(height: 20),

          // ── KPI Cards ────────────────────────────────────────────────
          summaryAsync.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (summary) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Row
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.payments_outlined,
                        iconBg: const Color(0xFFEEEDFE),
                        iconColor: kPurple,
                        label: 'cyber.total_revenue'.tr(),
                        value:
                            'EGP ${summary.totalRevenue.toStringAsFixed(0)}',
                        sub: '${summary.totalSessions} ${'cyber.sessions'.tr()}',
                      ),
                    ),

                    const SizedBox(width: kGap),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.receipt_long_outlined,
                        iconBg: const Color(0xFFFFF8EC),
                        iconColor: const Color(0xFFB06A00),
                        label: isAr ? 'مستحقات النظام' : 'System Dues',
                        value:
                            'EGP ${summary.pointsRevenue.toStringAsFixed(0)}',
                        sub: isAr ? 'إيرادات النقاط' : 'Points Revenue',
                      ),
                    ),
                    const SizedBox(width: kGap),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.people_outline,
                        iconBg: const Color(0xFFFCECEC),
                        iconColor: kRed,
                        label: 'cyber.sessions_breakdown'.tr(),
                        value:
                            '${summary.appSessions} App / ${summary.walkInSessions} ${'cyber.walk_in'.tr()}',
                        sub: '${'cyber.total_sessions'.tr()}: ${summary.totalSessions}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Charts + Room Breakdown Row ───────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily Revenue Chart
                    Expanded(
                      flex: 5,
                      child: _RevenueChart(
                        revenueByDay: summary.revenueByDay,
                        period: period,
                      ),
                    ),
                    const SizedBox(width: kGap),
                    // Room breakdown
                    Expanded(
                      flex: 2,
                      child: _RoomBreakdown(
                          revenueByRoom: summary.revenueByRoom,
                          totalRevenue: summary.totalRevenue),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Transactions Table ────────────────────────────────────────
          bookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (bookings) => _TransactionsTable(
                bookings: bookings, isAr: isAr),
          ),
        ],
      ),
    );
  }
}

// ─── Period Selector ─────────────────────────────────────────────────────────

class _PeriodSelector extends ConsumerWidget {
  final AccountingPeriod current;
  final bool isAr;
  const _PeriodSelector({required this.current, required this.isAr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodBtn(
            label: 'cyber.period_today'.tr(),
            selected: current == AccountingPeriod.today,
            onTap: () => ref.read(accountingPeriodProvider.notifier).state =
                AccountingPeriod.today,
          ),
          _PeriodBtn(
            label: 'cyber.period_week'.tr(),
            selected: current == AccountingPeriod.week,
            onTap: () => ref.read(accountingPeriodProvider.notifier).state =
                AccountingPeriod.week,
          ),
          _PeriodBtn(
            label: 'cyber.period_month'.tr(),
            selected: current == AccountingPeriod.month,
            onTap: () => ref.read(accountingPeriodProvider.notifier).state =
                AccountingPeriod.month,
          ),
        ],
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusSm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : kGray,
          ),
        ),
      ),
    );
  }
}

// ─── KPI Card ────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: kGray, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kSidebarText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(fontSize: 11, color: kGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Revenue Chart ───────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final Map<DateTime, double> revenueByDay;
  final AccountingPeriod period;

  const _RevenueChart(
      {required this.revenueByDay, required this.period});

  @override
  Widget build(BuildContext context) {
    // Build sorted day list
    final days = revenueByDay.keys.toList()..sort();
    final maxVal = revenueByDay.values.fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cyber.revenue_over_time'.tr(),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: kSidebarText),
          ),
          const SizedBox(height: 24),
          if (days.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: kBorder),
                    const SizedBox(height: 8),
                    Text('cyber.no_revenue_data'.tr(),
                        style: const TextStyle(color: kGray)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Y-axis labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(maxVal.toStringAsFixed(0),
                          style:
                              const TextStyle(fontSize: 10, color: kGray)),
                      Text((maxVal / 2).toStringAsFixed(0),
                          style:
                              const TextStyle(fontSize: 10, color: kGray)),
                      const Text('0',
                          style: TextStyle(fontSize: 10, color: kGray)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Bars
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final barWidth =
                          (constraints.maxWidth / days.length).clamp(
                              8.0, 48.0);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: days.map((day) {
                          final val = revenueByDay[day] ?? 0;
                          final frac = maxVal > 0 ? val / maxVal : 0.0;
                          final barH = (frac * 130).clamp(4.0, 130.0);
                          final label = period == AccountingPeriod.month
                              ? '${day.day}'
                              : DateFormat('E').format(day);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: 'EGP ${val.toStringAsFixed(0)}',
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  width: barWidth - 4,
                                  height: barH,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [kPurple, Color(0xFF8B83E0)],
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                style: const TextStyle(
                                    fontSize: 9, color: kGray),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Room Revenue Breakdown ───────────────────────────────────────────────────

class _RoomBreakdown extends StatelessWidget {
  final Map<String, double> revenueByRoom;
  final double totalRevenue;

  const _RoomBreakdown(
      {required this.revenueByRoom, required this.totalRevenue});

  static const _roomColors = [
    Color(0xFF534AB7),
    Color(0xFF0F6E56),
    Color(0xFFB06A00),
    Color(0xFFA32D2D),
    Color(0xFF1E88E5),
  ];

  @override
  Widget build(BuildContext context) {
    final rooms = revenueByRoom.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cyber.revenue_by_room'.tr(),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: kSidebarText),
          ),
          const SizedBox(height: 20),
          if (rooms.isEmpty)
            Center(
              child: Text('cyber.no_revenue_data'.tr(),
                  style: const TextStyle(color: kGray)),
            )
          else
            ...rooms.asMap().entries.map((entry) {
              final idx = entry.key;
              final room = entry.value;
              final pct = totalRevenue > 0 ? room.value / totalRevenue : 0.0;
              final color = _roomColors[idx % _roomColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(room.key,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kSidebarText),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          'EGP ${room.value.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: kBg,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 10, color: kGray),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Transactions Table ───────────────────────────────────────────────────────

class _TransactionsTable extends StatefulWidget {
  final List<Booking> bookings;
  final bool isAr;

  const _TransactionsTable(
      {required this.bookings, required this.isAr});

  @override
  State<_TransactionsTable> createState() => _TransactionsTableState();
}

class _TransactionsTableState extends State<_TransactionsTable> {
  String _query = '';

  List<Booking> get _filtered {
    if (_query.isEmpty) return widget.bookings;
    final q = _query.toLowerCase();
    return widget.bookings.where((b) {
      return (b.userName ?? '').toLowerCase().contains(q) ||
          (b.stationName ?? '').toLowerCase().contains(q) ||
          (b.roomName ?? '').toLowerCase().contains(q) ||
          b.status.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'cyber.all_transactions'.tr(),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kSidebarText),
                  ),
                ),
                // Search
                SizedBox(
                  width: 220,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'cyber.search_transactions'.tr(),
                      hintStyle:
                          const TextStyle(fontSize: 13, color: kGray),
                      prefixIcon:
                          const Icon(Icons.search, size: 18, color: kGray),
                      filled: true,
                      fillColor: kBg,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kRadiusSm),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Column Headers
          Container(
            color: kBg,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _ColHead('cyber.date_time'.tr(), flex: 3),
                _ColHead('cyber.client'.tr(), flex: 2),
                _ColHead('cyber.room'.tr(), flex: 2),
                _ColHead('cyber.station'.tr(), flex: 2),
                _ColHead('cyber.duration'.tr(), flex: 1),
                _ColHead('cyber.session_cost'.tr(), flex: 2),
                _ColHead('cyber.total_col'.tr(), flex: 2),
                _ColHead('cyber.type_col'.tr(), flex: 2),
                _ColHead('cyber.status_col'.tr(), flex: 2),
              ],
            ),
          ),

          // Rows
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('cyber.no_transactions'.tr(),
                    style: const TextStyle(color: kGray)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 0.5, color: kBorder),
              itemBuilder: (_, i) {
                final b = filtered[i];
                return _TransactionRow(booking: b);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ColHead extends StatelessWidget {
  final String label;
  final int flex;
  const _ColHead(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kGray,
            letterSpacing: 0.4),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Booking booking;
  const _TransactionRow({required this.booking});

  Color get _statusColor {
    if (booking.isConfirmed || booking.isCompleted) return kTeal;
    if (booking.isCancelled || booking.isRejected) return kRed;
    return kAmber;
  }

  Color get _statusBg {
    if (booking.isConfirmed || booking.isCompleted)
      return const Color(0xFFE6F7F3);
    if (booking.isCancelled || booking.isRejected)
      return const Color(0xFFFCECEC);
    return const Color(0xFFFFF8EC);
  }

  @override
  Widget build(BuildContext context) {
    final localStart = booking.startTime.toLocal();
    final dateStr = DateFormat('MMM d, HH:mm').format(localStart);
    final client = booking.source == 'manual'
        ? (booking.userName ?? 'Walk-in')
        : (booking.userName ?? 'App user');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: _Cell(dateStr)),
          Expanded(flex: 2, child: _Cell(client)),
          Expanded(
              flex: 2, child: _Cell(booking.roomName ?? '—')),
          Expanded(
              flex: 2, child: _Cell(booking.stationName ?? '—')),
          Expanded(
              flex: 1,
              child: _Cell(
                  '${booking.durationHours.toStringAsFixed(1)}h')),
          Expanded(
              flex: 2,
              child: _Cell(
                  'EGP ${booking.roomCost.toStringAsFixed(0)}')),
          Expanded(
              flex: 2,
              child: Text(
                'EGP ${(booking.totalAmount - booking.bookingFee).toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kSidebarText),
              )),
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: booking.source == 'manual'
                    ? const Color(0xFFF0F0FF)
                    : const Color(0xFFE6F7F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                booking.source == 'manual' ? 'Walk-in' : 'App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: booking.source == 'manual'
                      ? kPurple
                      : kTeal,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                booking.statusDisplay,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: kSidebarText),
      overflow: TextOverflow.ellipsis,
    );
  }
}
