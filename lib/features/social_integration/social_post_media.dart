/// Local checks for a file the user picked. Nothing is uploaded here.
class SocialPostMedia {
  const SocialPostMedia({
    required this.name,
    required this.kind,
    required this.bytes,
  });

  final String name;
  final SocialMediaKind kind;
  final int bytes;

  static const imageLimit = 8 * 1024 * 1024;
  static const videoLimit = 50 * 1024 * 1024;
  static const documentLimit = 10 * 1024 * 1024;

  static SocialPostMedia? validate({
    required String name,
    required int bytes,
    required SocialMediaKind kind,
  }) {
    final lower = name.toLowerCase();
    final allowed = switch (kind) {
      SocialMediaKind.image => ['.jpg', '.jpeg', '.png', '.webp'],
      SocialMediaKind.video => ['.mp4', '.mov'],
      SocialMediaKind.document => ['.pdf', '.doc', '.docx'],
    };
    if (!allowed.any(lower.endsWith)) return null;
    final limit = switch (kind) {
      SocialMediaKind.image => imageLimit,
      SocialMediaKind.video => videoLimit,
      SocialMediaKind.document => documentLimit,
    };
    if (bytes <= 0 || bytes > limit) return null;
    return SocialPostMedia(name: name, kind: kind, bytes: bytes);
  }
}

enum SocialMediaKind { image, video, document }
