class VersionComparator {
  VersionComparator._();

  /// Returns:
  /// > 0 if versionA is greater than versionB
  /// < 0 if versionA is less than versionB
  /// 0 if equal
  static int compare(String versionA, String versionB) {
    final cleanA = _cleanVersion(versionA);
    final cleanB = _cleanVersion(versionB);

    final partsA = cleanA.split('.').map(int.tryParse).toList();
    final partsB = cleanB.split('.').map(int.tryParse).toList();

    final maxLen = partsA.length > partsB.length ? partsA.length : partsB.length;

    for (var i = 0; i < maxLen; i++) {
      final a = (i < partsA.length ? partsA[i] : 0) ?? 0;
      final b = (i < partsB.length ? partsB[i] : 0) ?? 0;

      if (a != b) {
        return a.compareTo(b);
      }
    }
    return 0;
  }

  /// Checks if remoteVersion is newer than localVersion
  static bool isUpdateAvailable(String localVersion, String remoteVersion) {
    return compare(remoteVersion, localVersion) > 0;
  }

  static String _cleanVersion(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    // Remove metadata like +1 or -beta
    final plusIndex = s.indexOf('+');
    if (plusIndex != -1) {
      s = s.substring(0, plusIndex);
    }
    final dashIndex = s.indexOf('-');
    if (dashIndex != -1) {
      s = s.substring(0, dashIndex);
    }
    return s;
  }
}
