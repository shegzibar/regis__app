void main() {
  try {
    print(DateTime.parse('2026-07-31T11:30:00+00:00Z'));
  } catch (e) {
    print('Error: $e');
  }
}
