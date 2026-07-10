import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/room.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class ManualBookingPage extends ConsumerStatefulWidget {
  const ManualBookingPage({super.key});
  @override
  ConsumerState<ManualBookingPage> createState() => _ManualBookingPageState();
}

class _ManualBookingPageState extends ConsumerState<ManualBookingPage> {
  String? selectedRoomId;
  String? selectedRoomType;
  double selectedRoomPrice = 15;
  String? selectedStationId;
  int durationHours = 2;
  TimeOfDay startTime = TimeOfDay.now();
  String paymentMethod = 'cash';
  final clientNameController = TextEditingController();
  bool isSubmitting = false;
  bool bookingSuccess = false;

  double get total => selectedRoomPrice * durationHours;

  Future<void> _submitBooking() async {
    if (selectedStationId == null || selectedRoomId == null) return;
    setState(() => isSubmitting = true);

    try {
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      await ref.read(cdBookingRepoProvider).addManualBooking(
            stationId: selectedStationId!,
            startTime: start,
            durationHours: durationHours,
            pricePerHour: selectedRoomPrice,
            paymentMethod: paymentMethod,
            clientName: clientNameController.text.trim().isEmpty
                ? null
                : clientNameController.text.trim(),
          );

      if (mounted) {
        setState(() => bookingSuccess = true);
        ref.invalidate(todayBookingsProvider);
        ref.invalidate(todayRevenueProvider);
        ref.invalidate(stationStatusProvider(selectedRoomId!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final rooms = ref.watch(cyberRoomsProvider);
    final bookingsAsync = ref.watch(todayBookingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Text(
            'cyber.manual_booking_walkin_customer'.tr(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          Text(
            'cyber.for_customers_who_come'.tr(),
            style: const TextStyle(fontSize: 12, color: kGray),
          ),
          const SizedBox(height: 14),

          // Two column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Form
              Expanded(
                flex: 3,
                child: Column(children: [
                  _buildFormPanel(isAr, rooms),
                  if (bookingSuccess) ...[
                    const SizedBox(height: kGap),
                    _buildSuccessBanner(isAr),
                  ],
                ]),
              ),
              const SizedBox(width: kGap),
              // RIGHT: Today's manual bookings
              Expanded(
                flex: 2,
                child: Column(children: [
                  _buildTodayManualList(isAr, bookingsAsync),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(bool isAr, AsyncValue<List<Room>> rooms) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'cyber.booking_details'.tr(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5),

          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room type chips
                Text('cyber.room_type'.tr(),
                    style: const TextStyle(fontSize: 11, color: kGray)),
                const SizedBox(height: 6),
                rooms.when(
                  data: (roomList) => Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: roomList.map((room) {
                      final isSelected = selectedRoomId == room.id;
                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedRoomId = room.id;
                          selectedRoomPrice = room.pricePerHour;
                          selectedRoomType = room.type;
                          selectedStationId = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? kPurpleLight : kBg,
                            border: Border.all(
                                color: isSelected ? kPurpleMid : kBorder),
                            borderRadius: BorderRadius.circular(kRadiusSm),
                          ),
                          child: Text(
                            '${room.name} — ${room.pricePerHour.toInt()} EGP/hr',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? kPurple : kGray,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 12),

                // Station grid
                if (selectedRoomId != null) ...[
                  Text('cyber.station'.tr(),
                      style: const TextStyle(fontSize: 11, color: kGray)),
                  const SizedBox(height: 6),
                  Consumer(builder: (context, ref, _) {
                    final stations =
                        ref.watch(stationStatusProvider(selectedRoomId!));
                    return stations.when(
                      data: (stationList) => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 7,
                          crossAxisSpacing: 7,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: stationList.length,
                        itemBuilder: (_, i) {
                          final s = stationList[i];
                          final isBusy = s.isBusy;
                          final isMaint = !s.isActive;
                          final isSelected = selectedStationId == s.id;
                          final isDisabled = isBusy || isMaint;

                          Color borderColor = kBorder;
                          Color bgColor = kBg;
                          if (isSelected) {
                            borderColor = kPurple;
                            bgColor = kPurpleLight;
                          } else if (isBusy) {
                            borderColor = kPurpleMid;
                          } else if (isMaint) {
                            borderColor = Colors.red.shade200;
                          }

                          return GestureDetector(
                            onTap: isDisabled
                                ? null
                                : () => setState(() => selectedStationId = s.id),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(
                                    color: borderColor, width: 0.5),
                                borderRadius: BorderRadius.circular(kRadiusSm),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.name,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500)),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isMaint
                                              ? Colors.red
                                              : isBusy
                                                  ? kPurple
                                                  : kTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    s.statusLabel(arabic: isAr),
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        color: isMaint
                                            ? kRed
                                            : isBusy
                                                ? kPurple
                                                : kTeal),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('$e'),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // Start time + Duration row
                Row(children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('cyber.start_time'.tr(),
                          style: const TextStyle(fontSize: 11, color: kGray)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                              context: context, initialTime: startTime);
                          if (picked != null) {
                            setState(() => startTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: kBorder, width: 0.5),
                            borderRadius: BorderRadius.circular(kRadiusSm),
                          ),
                          child: Text(startTime.format(context),
                              style: const TextStyle(fontSize: 12.5)),
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('cyber.duration'.tr(),
                          style: const TextStyle(fontSize: 11, color: kGray)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: durationHours,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSm),
                            borderSide:
                                const BorderSide(color: kBorder, width: 0.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        items: [1, 2, 3, 4, 5, 6, 7, 8]
                            .map((h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(
                                    isAr
                                        ? (h == 1 ? 'ساعة' : '$h ساعات')
                                        : (h == 1 ? '1 hr' : '$h hrs'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => durationHours = v ?? 2),
                      ),
                    ],
                  )),
                ]),
                const SizedBox(height: 10),

                // Client name
                Text(
                    'cyber.client_name_optional'.tr(),
                    style: const TextStyle(fontSize: 11, color: kGray)),
                const SizedBox(height: 4),
                TextField(
                  controller: clientNameController,
                  decoration: InputDecoration(
                    hintText: 'cyber.eg_mohamed_ahmed'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSm),
                      borderSide: const BorderSide(color: kBorder, width: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 10),

                // Payment method
                Text('cyber.payment_method'.tr(),
                    style: const TextStyle(fontSize: 11, color: kGray)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSm),
                      borderSide: const BorderSide(color: kBorder, width: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'cash',
                        child: Text('Cash', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'instapay',
                        child:
                            Text('InstaPay', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'vodafone_cash',
                        child: Text('Vodafone Cash',
                            style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'fawry',
                        child: Text('Fawry', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) => setState(() => paymentMethod = v ?? 'cash'),
                ),
                const SizedBox(height: 12),

                // Total
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(kRadiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('cyber.total'.tr(),
                          style: const TextStyle(fontSize: 12, color: kGray)),
                      Text('${total.toInt()} EGP',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: kPurple)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusSm)),
                    ),
                    onPressed: (selectedStationId != null && !isSubmitting)
                        ? _submitBooking
                        : null,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                color: kWhite, strokeWidth: 2))
                        : Text(
                            'cyber.confirm_booking_and_add'.tr(),
                            style:
                                const TextStyle(color: kWhite, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kGreen),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: kGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'cyber.booking_added_successfully'.tr(),
              style: const TextStyle(
                  color: kGreen, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kGreen, size: 18),
            onPressed: () => setState(() => bookingSuccess = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayManualList(bool isAr, AsyncValue bookingsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              isAr ? 'حجوزاتك اليدوية اليوم' : "Today's Manual Bookings",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5),
          bookingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e', style: const TextStyle(color: kRed)),
            ),
            data: (bookings) {
              final manualBookings =
                  bookings.where((b) => b.source == 'manual').toList();

              if (manualBookings.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'cyber.no_manual_bookings_yet'.tr(),
                      style: const TextStyle(color: kGray, fontSize: 12),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: manualBookings.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 0.5, thickness: 0.5),
                itemBuilder: (_, i) {
                  final b = manualBookings[i];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.userName ?? ('cyber.walkin'.tr()),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${DateFormat('HH:mm').format(b.startTime)} → ${DateFormat('HH:mm').format(b.endTime)}',
                                style:
                                    const TextStyle(fontSize: 11, color: kGray),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${b.totalAmount.toInt()} EGP',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kTeal),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
