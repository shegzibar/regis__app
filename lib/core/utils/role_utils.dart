import '../../data/models/user.dart';

/// Platform admins/managers can approve online payment queues.
bool canApproveOnlineBookings(AppUser? user) {
  if (user == null) return false;
  return user.isAdmin || user.isManager;
}

/// Owner cyber dashboard navigation (admin gets extra items).
bool showOwnerAdminNavItems(AppUser? user) => user?.isAdmin == true;
