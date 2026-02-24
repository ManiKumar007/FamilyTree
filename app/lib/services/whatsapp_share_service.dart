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
      print('Error sharing to WhatsApp: $e');
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

मैंने $memberCount परिवार के सदस्यों को Vansh पर जोड़ा है! 🌳

अपने परिवार की विरासत को सुरक्षित रखें। 
आज ही अपना family tree बनाएं:
$appUrl

#Vansh #FamilyTree #Heritage #Legacy
''';
  }

  /// Generate milestone for discovering generations
  static String generateGenerationMilestone(int generationCount) {
    final emojis = ['👶', '👨', '👴', '🧓', '👵', '📜', '⏳', '🏛️'];
    final emoji = emojis[generationCount.clamp(0, emojis.length - 1)];

    return '''
📜 $emoji मैंने अपनी $generationCount पीढ़ियों को खोज लिया!

From my great-great-grandparents to today's generation,
our family's story is preserved on Vansh! 

अपने पूर्वजों से जुड़ें:
$appUrl

#Vansh #FamilyHistory #Generations #Heritage
''';
  }

  /// Generate birthday reminder milestone
  static String generateBirthdayMilestone(String personName, int age) {
    return '''
🎂 Happy Birthday $personName! $age साल के हो गए!

Vansh पर सभी family members के birthdays याद रखें और celebrate करें! 🎉

अपने परिवार को organize करें:
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

$person1 ❤️ $person2 की शादी की $years वीं सालगिरह! 🎊

Vansh पर सभी family milestones celebrate करें।

$appUrl

#Anniversary #FamilyLove #Vansh
''';
  }

  /// Generate photo upload milestone
  static String generatePhotoMilestone(int photoCount) {
    return '''
📸 $photoCount family photos uploaded!

यादें हमेशा के लिए सुरक्षित! 

अपनी family की stories और photos को preserve करें Vansh पर:
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
नमस्ते $recipientName! 🙏

$inviterName ने आपको Vansh family tree में जोड़ा है$relationship!

🌳 अपनी profile claim करें और पूरा परिवार देखें
📸 Photos और memories share करें
👨‍👩‍👧‍👦 सभी relatives से connect हों

अभी join करें:
$appUrl

- Vansh Family Tree टीम
''';
  }

  /// Generate merge request milestone
  static String generateMergeSuccessMessage(
    String person1,
    String person2,
    int newFamilySize,
  ) {
    return '''
🤝 परिवार और बड़ा हो गया!

$person1 की family tree $person2 के साथ merge हो गई!

अब कुल $newFamilySize family members! 🎊

Vansh पर अपने पूरे परिवार को connect करें:
$appUrl

#FamilyReunion #Vansh #TogetherAgain
''';
  }

  /// Generate profile completion milestone
  static String generateProfileCompletionMessage() {
    return '''
✅ Profile Complete!

मैंने अपनी complete family profile Vansh पर बना ली है! 

घर बैठे अपनी family tree बनाएं:
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

जानें अपनी family की कहानी:
$appUrl

#Vansh #FamilyStories
''';
  }

  /// Share app download link
  static String generateAppShareMessage() {
    return '''
🌳 Vansh - अपने परिवार की विरासत सुरक्षित रखें

✨ आसानी से family tree बनाएं
📱 Phone number से relatives को ढूंढें
🔒 Secure और private
🇮🇳 भारतीय परिवारों के लिए specially designed

अभी free में शुरू करें:
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
