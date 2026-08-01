void main() {
  try {
    print(DateTime.parse('2026-07-31 12:00:00Z'));
  } catch(e) {
    print("ERROR SPACE Z: $e");
  }

  try {
    print(DateTime.parse('2026-07-31T12:00:00Z'));
  } catch(e) {
    print("ERROR T Z: $e");
  }
}
