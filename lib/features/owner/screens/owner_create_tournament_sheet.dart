import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/tournament.dart';
import '../../../data/repositories/tournament_repository.dart';

class OwnerCreateTournamentSheet extends StatefulWidget {
  final String cyberId;
  const OwnerCreateTournamentSheet({super.key, required this.cyberId});

  @override
  State<OwnerCreateTournamentSheet> createState() =>
      _OwnerCreateTournamentSheetState();
}

class _OwnerCreateTournamentSheetState
    extends State<OwnerCreateTournamentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _gameCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController();
  final _maxCtrl = TextEditingController(text: '16');

  DateTime _startDate = DateTime.now().add(const Duration(hours: 2));
  bool _isLoading = false;

  static const List<String> _popularGames = [
    'FIFA',
    'EA FC 25',
    'Mortal Kombat',
    'Street Fighter',
    'Call of Duty',
    'Fortnite',
    'Free Fire',
    'PUBG',
    'Tekken 8',
    'Counter-Strike 2',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _gameCtrl.dispose();
    _prizeCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
    );
    if (time == null) return;
    setState(() {
      _startDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final tournament = Tournament(
        id: '', // DB will generate
        name: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        type: 'local',
        cyberId: widget.cyberId,
        adminId: '', // Optionally pass the current user's ID here
        gameType: _gameCtrl.text.trim(),
        maxPlayers: int.parse(_maxCtrl.text.trim()),
        startDate: _startDate,
        endDate: _startDate.add(const Duration(hours: 3)),
        status: 'registration',
        prizePool: double.tryParse(
                _prizeCtrl.text.trim().replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0,
        prizePerHour: 1.0,
        createdAt: now,
        updatedAt: now,
      );
      await TournamentRepository().createLocalTournament(tournament);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events,
                      color: Color(0xFF7C3AED)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Create Tournament',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D21),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  _buildLabel('Tournament Title *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: _inputDecoration('e.g. Summer FIFA Championship'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Game — with quick-select chips
                  _buildLabel('Game *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _gameCtrl,
                    decoration: _inputDecoration('e.g. FIFA, Tekken 8'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _popularGames.map((g) {
                      return GestureDetector(
                        onTap: () => setState(() => _gameCtrl.text = g),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _gameCtrl.text == g
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFFF0E6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _gameCtrl.text == g
                                  ? Colors.white
                                  : const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildLabel('Description (optional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: _inputDecoration(
                        'Rules, format, requirements…'),
                  ),
                  const SizedBox(height: 16),

                  // Prize + Max Participants in a row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Prize Pool (optional)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _prizeCtrl,
                              decoration:
                                  _inputDecoration('e.g. 500 EGP + Trophy'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Max Participants *'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _maxCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: _inputDecoration('16'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                final n = int.tryParse(v);
                                if (n == null || n < 2) {
                                  return 'Min 2';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Entry fee info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Color(0xFF7C3AED), size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Entry Fee: 10 Wallet Points per participant',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start Date/Time
                  _buildLabel('Start Date & Time *'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEE, MMM d yyyy • hh:mm a')
                                .format(_startDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1D21),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Create Tournament',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
    );
  }
}
