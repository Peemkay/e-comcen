/// Nigerian Army Corps
final List<String> nigerianArmyCorps = [
  'Nigerian Army Infantry Corps',
  'Nigerian Army Armoured Corps',
  'Nigerian Army Artillery Corps',
  'Nigerian Army Engineers',
  'Nigerian Army Signals',
  'Nigerian Army Intelligence Corps',
  'Nigerian Army Supply and Transport Corps',
  'Nigerian Army Medical Corps',
  'Nigerian Army Ordnance Corps',
  'Nigerian Army Electrical and Mechanical Engineers',
  'Nigerian Army Education Corps',
  'Nigerian Army Military Police Corps',
  'Nigerian Army Physical Training Corps',
  'Nigerian Army Chaplain Services (Protestant)',
  'Nigerian Army Chaplain Services (Catholic)',
  'Nigerian Army Islamic Corps',
  'Nigerian Army Legal Services',
  'Nigerian Army Public Relations Corps',
  'Nigerian Army Finance Corps',
];

/// Nigerian Army Officer Ranks
final List<String> officerRanks = [
  'Second Lieutenant',
  'Lieutenant',
  'Captain',
  'Major',
  'Lieutenant Colonel',
  'Colonel',
  'Brigadier General',
  'Major General',
  'Lieutenant General',
  'General',
];

/// Nigerian Army Non-Commissioned Officer and Soldier Ranks
final List<String> soldierRanks = [
  'Private',
  'Lance Corporal',
  'Corporal',
  'Sergeant',
  'Staff Sergeant',
  'Warrant Officer',
  'Master Warrant Officer',
  'Army Warrant Officer',
];

/// All Nigerian Army Ranks
final List<String> allRanks = [...officerRanks, ...soldierRanks];

/// Check if a rank is an officer rank
bool isOfficerRank(String rank) {
  return officerRanks.contains(rank);
}

/// Validate army number format
bool isValidArmyNumber(String armyNumber) {
  // Accept any non-empty army number format
  // This is an extremely permissive validation to accommodate all possible formats
  // including N/12345, 20NA/23/123456, or any other format

  // Only check that it's not empty and contains at least one alphanumeric character
  final bool isNotEmpty = armyNumber.trim().isNotEmpty;
  final bool hasAlphanumeric = RegExp(r'[A-Za-z0-9]').hasMatch(armyNumber);

  return isNotEmpty && hasAlphanumeric;
}
