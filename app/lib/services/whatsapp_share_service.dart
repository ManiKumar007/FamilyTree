import 'package:url_launcher/url_launcher.dart';

/// WhatsApp Sharing Service for Viral Growth
/// 
/// Generates shareable milestone messages and opens WhatsApp with pre-filled text
class WhatsAppShareService {
  static const String appUrl = 'https://familytree-web.vercel.app';
  static const String appName = 'Vansh'; // Updated branding

  /// Share a milestone to WhatsApp
  static Future<bool> shareMilestone({
    required String message,
    String? phoneNumber,
  }) async {
    final encodedMessage = Uri.encodeComponent(message);
    
    // WhatsApp URI scheme
    final Uri whatsappUri = phoneNumber != null
        ? Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encodedMessage')
        : Uri.parse('whatsapp://send?text=$encodedMessage');

    try {
      final bool launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      return false;
    }
  }

  /// Generate milestone message when family tree reaches certain size
  static String generateTreeSizeMilestone(int memberCount) {
    final emojis = {
      10: '🌱',
      25: '🌿',
      50: '🌳',
      100: '🏆',
      250: '🎉',
      500: '👑',
    };

    final emoji = emojis.entries
        .where((e) => memberCount >= e.key)
        .lastOrNull?.value ?? '🌱';

    final messages = {
      10: 'My family tree just started growing!',
      25: 'Quarter-century of connections!',
      50: 'Half a hundred family members discovered!',
      100: 'Crossed 100 family members!',
      250: 'Amazing! Over 250 relatives connected!',
      500: 'Incredible! 500+ family members preserved!',
    };

    final message = messages.entries
        .where((e) => memberCount >= e.key)
        .lastOrNull?.value ?? 'Started building my family tree!';

    return '''
$emoji $message

I've added $memberCount family members to Vansh! 🌳

Preserve your family's heritage.
Start your family tree today:
$appUrl

#Vansh #FamilyTree #Heritage #Legacy
''';
  }

  /// Generate milestone for discovering generations
  static String generateGenerationMilestone(int generationCount) {
    final emojis = ['👶', '👨', '👴', '🧓', '👵', '📜', '⏳', '🏛️'];
    final emoji = emojis[generationCount.clamp(0, emojis.length - 1)];

    return '''
📜 $emoji Discovered $generationCount generations of my family!

From my great-great-grandparents to today's generation,
our family's story is preserved on Vansh! 

Connect with your ancestors:
$appUrl

#Vansh #FamilyHistory #Generations #Heritage
''';
  }

  /// Generate birthday reminder milestone
  static String generateBirthdayMilestone(String personName, int age) {
    return '''
🎂 Happy Birthday $personName! Turning $age today!

Remember and celebrate all family birthdays on Vansh! 🎉

Organize your family:
$appUrl

#HappyBirthday #FamilyFirst #Vansh
''';
  }

  /// Generate anniversary milestone
  static String generateAnniversaryMilestone(
    String person1,
    String person2,
    int years,
  ) {
    return '''
💍 $years years of love!

$person1 ❤️ $person2 celebrating $years years of marriage! 🎊

Celebrate all family milestones on Vansh.

$appUrl

#Anniversary #FamilyLove #Vansh
''';
  }

  /// Generate photo upload milestone
  static String generatePhotoMilestone(int photoCount) {
    return '''
📸 $photoCount family photos uploaded!

Memories preserved forever! 

Preserve your family's stories and photos on Vansh:
$appUrl

#Memories #FamilyPhotos #Vansh #Heritage
''';
  }

  /// Generate invite message for family members
  static String generateInviteMessage({
    required String inviterName,
    required String recipientName,
    String? relationshipType,
  }) {
    final relationship = relationshipType != null
        ? ' as your $relationshipType'
        : '';

    return '''
Hello $recipientName! 👋

$inviterName has added you to the Vansh family tree$relationship!

🌳 Claim your profile and see your whole family
📸 Share photos and memories
👨‍👩‍👧‍👦 Connect with all relatives

Join now:
$appUrl

- Vansh Family Tree Team
''';
  }

  /// Generate merge request milestone
  static String generateMergeSuccessMessage(
    String person1,
    String person2,
    int newFamilySize,
  ) {
    return '''
🤝 Family just got bigger!

$person1's family tree merged with $person2!

Now $newFamilySize total family members! 🎊

Connect your whole family on Vansh:
$appUrl

#FamilyReunion #Vansh #TogetherAgain
''';
  }

  /// Generate profile completion milestone
  static String generateProfileCompletionMessage() {
    return '''
✅ Profile Complete!

I've created my complete family profile on Vansh! 

Build your family tree from home:
$appUrl

#ProfileComplete #FamilyTree #Vansh
''';
  }

  /// Generate custom milestone
  static String generateCustomMilestone({
    required String title,
    required String description,
    String? emoji,
  }) {
    final icon = emoji ?? '🎉';
    return '''
$icon $title

$description

Discover your family's story:
$appUrl

#Vansh #FamilyStories
''';
  }

  /// Share app download link
  static String generateAppShareMessage() {
    return '''
🌳 Vansh - Preserve Your Family's Heritage

✨ Easily build your family tree
📱 Find relatives by phone number
🔒 Secure and private
🇮🇳 Specially designed for Indian families

Start free now:
$appUrl

#Vansh #FamilyTree #Heritage
''';
  }

  /// Get WhatsApp status update (shorter format)
  static String generateWhatsAppStatus(MilestoneType type, Map<String, dynamic> data) {
    switch (type) {
      case MilestoneType.treeSize:
        final count = data['count'] as int;
        return '🌳 ${count}+ family members on Vansh!\n\nBuild yours: $appUrl';
      
      case MilestoneType.generations:
        final gens = data['generations'] as int;
        return '📜 Discovered $gens generations!\n\nConnect with ancestors: $appUrl';
      
      case MilestoneType.birthday:
        final name = data['name'] as String;
        return '🎂 Happy Birthday $name!\n\nCelebrate on Vansh: $appUrl';
      
      case MilestoneType.photos:
        final count = data['count'] as int;
        return '📸 $count memories preserved!\n\nSave yours: $appUrl';
      
      default:
        return generateAppShareMessage();
    }
  }

  /// Check if WhatsApp is installed
  static Future<bool> canShareToWhatsApp() async {
    final Uri whatsappUri = Uri.parse('whatsapp://send');
    return await canLaunchUrl(whatsappUri);
  }
}

/// Milestone types for tracking and analytics
enum MilestoneType {
  treeSize,
  generations,
  birthday,
  anniversary,
  photos,
  profileComplete,
  mergeSuccess,
  custom,
}

/// Milestone data class for tracking
class Milestone {
  final MilestoneType type;
  final String message;
  final DateTime achievedAt;
  final Map<String, dynamic> metadata;

  Milestone({
    required this.type,
    required this.message,
    required this.achievedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'message': message,
    'achievedAt': achievedAt.toIso8601String(),
    'metadata': metadata,
  };
}
