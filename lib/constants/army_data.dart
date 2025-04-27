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

/// Generate a sample army number based on rank
String generateSampleArmyNumber(String rank) {
  if (isOfficerRank(rank)) {
    return 'N/12345'; // Sample officer number
  } else {
    return '20NA/23/123456'; // Sample soldier number
  }
}

/// Validate army number format
bool isValidArmyNumber(String armyNumber) {
  // This is a very flexible validation that allows for various formats
  // Officers: Usually starts with N/ or NA/ followed by numbers (e.g., NA/12345)
  // Soldiers: Usually has format like 20NA/23/123456

  // We're using a non-strict approach - just check for basic validity
  // Allow any alphanumeric with forward slashes, no special characters
  final RegExp armyNumberRegex = RegExp(r'^[A-Za-z0-9\/\-]+$');

  // Basic check - must contain at least one letter and one number
  final bool hasLetter = RegExp(r'[A-Za-z]').hasMatch(armyNumber);
  final bool hasNumber = RegExp(r'[0-9]').hasMatch(armyNumber);

  return armyNumberRegex.hasMatch(armyNumber) && hasLetter && hasNumber;
}
