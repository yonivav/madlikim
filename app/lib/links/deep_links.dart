/// Links the app understands (Vision, 34.4):
///   https://madlikim.app/j/{code}   join a shared menorah
///   https://madlikim.app/i/{id}     open a "come light with me" invite
///   madlikim://j/{code}, madlikim://i/{id}   same, custom scheme
sealed class DeepLink {
  const DeepLink();

  static DeepLink? parse(Uri uri) {
    final segments = [
      if (uri.scheme == 'madlikim' && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((s) => s.isNotEmpty),
    ];
    if (segments.length < 2) return null;
    final value = segments[1];
    return switch (segments[0]) {
      'j' => JoinGroupLink(value.toUpperCase()),
      'i' => OpenInviteLink(value),
      _ => null,
    };
  }
}

class JoinGroupLink extends DeepLink {
  const JoinGroupLink(this.code);
  final String code;
}

class OpenInviteLink extends DeepLink {
  const OpenInviteLink(this.inviteId);
  final String inviteId;
}
