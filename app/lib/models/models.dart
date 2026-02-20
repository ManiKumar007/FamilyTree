/// Data models for the MyFamilyTree app.

class Person {
  final String id;
  final String? username;
  final String name;
  final String? givenName;
  final String? surname;
  final String? dateOfBirth;
  final String? dateOfDeath;
  final String? placeOfDeath;
  final bool isAlive;
  final String gender; // 'male', 'female', 'other'
  final String? photoUrl;
  final String phone;
  final String? email;
  final String? occupation;
  final String? community;
  final String? gotra;
  final String? city;
  final String? state;
  final String maritalStatus; // 'single', 'married', 'divorced', 'widowed'
  final String? weddingDate;
  final String? nakshatra;
  final String? rashi;
  final String? nativePlace;
  final String? ancestralVillage;
  final String? subCaste;
  final String? kulaDevata;
  final String? pravara;
  final bool isProfilePublic;
  final String? createdByUserId;
  final String? authUserId;
  final bool verified;
  final String? createdAt;
  final String? updatedAt;

  const Person({
    required this.id,
    this.username,
    required this.name,
    this.givenName,
    this.surname,
    this.dateOfBirth,
    this.dateOfDeath,
    this.placeOfDeath,
    this.isAlive = true,
    required this.gender,
    this.photoUrl,
    required this.phone,
    this.email,
    this.occupation,
    this.community,
    this.gotra,
    this.city,
    this.state,
    this.maritalStatus = 'single',
    this.weddingDate,
    this.nakshatra,
    this.rashi,
    this.nativePlace,
    this.ancestralVillage,
    this.subCaste,
    this.kulaDevata,
    this.pravara,
    this.isProfilePublic = false,
    this.createdByUserId,
    this.authUserId,
    this.verified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      username: json['username'] as String?,
      name: json['name'] as String,
      givenName: json['given_name'] as String?,
      surname: json['surname'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      dateOfDeath: json['date_of_death'] as String?,
      placeOfDeath: json['place_of_death'] as String?,
      isAlive: json['is_alive'] as bool? ?? true,
      gender: json['gender'] as String,
      photoUrl: json['photo_url'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      occupation: json['occupation'] as String?,
      community: json['community'] as String?,
      gotra: json['gotra'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      maritalStatus: json['marital_status'] as String? ?? 'single',
      weddingDate: json['wedding_date'] as String?,
      nakshatra: json['nakshatra'] as String?,
      rashi: json['rashi'] as String?,
      nativePlace: json['native_place'] as String?,
      ancestralVillage: json['ancestral_village'] as String?,
      subCaste: json['sub_caste'] as String?,
      kulaDevata: json['kula_devata'] as String?,
      pravara: json['pravara'] as String?,
      isProfilePublic: json['is_profile_public'] as bool? ?? false,
      createdByUserId: json['created_by_user_id'] as String?,
      authUserId: json['auth_user_id'] as String?,
      verified: json['verified'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'given_name': givenName,
      'surname': surname,
      'date_of_birth': dateOfBirth,
      'date_of_death': dateOfDeath,
      'place_of_death': placeOfDeath,
      'is_alive': isAlive,
      'gender': gender,
      'photo_url': photoUrl,
      'phone': phone,
      'email': email,
      'occupation': occupation,
      'community': community,
      'gotra': gotra,
      'city': city,
      'state': state,
      'marital_status': maritalStatus,
      'wedding_date': weddingDate,
      'nakshatra': nakshatra,
      'rashi': rashi,
      'native_place': nativePlace,
      'ancestral_village': ancestralVillage,
      'sub_caste': subCaste,
      'kula_devata': kulaDevata,
      'pravara': pravara,
      'is_profile_public': isProfilePublic,
      'created_by_user_id': createdByUserId,
      'auth_user_id': authUserId,
      'verified': verified,
    };
  }

  /// Get age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Get birth year
  String? get birthYear {
    if (dateOfBirth == null) return null;
    final dob = DateTime.tryParse(dateOfBirth!);
    return dob?.year.toString();
  }

  Person copyWith({
    String? name,
    String? username,
    String? givenName,
    String? surname,
    String? dateOfBirth,
    String? dateOfDeath,
    String? placeOfDeath,
    bool? isAlive,
    String? gender,
    String? photoUrl,
    String? phone,
    String? email,
    String? occupation,
    String? community,
    String? gotra,
    String? city,
    String? state,
    String? maritalStatus,
    String? weddingDate,
    String? nakshatra,
    String? rashi,
    String? nativePlace,
    String? ancestralVillage,
    String? subCaste,
    String? kulaDevata,
    String? pravara,
    bool? isProfilePublic,
    bool? verified,
  }) {
    return Person(
      id: id,
      username: username ?? this.username,
      name: name ?? this.name,
      givenName: givenName ?? this.givenName,
      surname: surname ?? this.surname,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      placeOfDeath: placeOfDeath ?? this.placeOfDeath,
      isAlive: isAlive ?? this.isAlive,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      occupation: occupation ?? this.occupation,
      community: community ?? this.community,
      gotra: gotra ?? this.gotra,
      city: city ?? this.city,
      state: state ?? this.state,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      weddingDate: weddingDate ?? this.weddingDate,
      nakshatra: nakshatra ?? this.nakshatra,
      rashi: rashi ?? this.rashi,
      nativePlace: nativePlace ?? this.nativePlace,
      ancestralVillage: ancestralVillage ?? this.ancestralVillage,
      subCaste: subCaste ?? this.subCaste,
      kulaDevata: kulaDevata ?? this.kulaDevata,
      pravara: pravara ?? this.pravara,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      createdByUserId: createdByUserId,
      authUserId: authUserId,
      verified: verified ?? this.verified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class Relationship {
  final String id;
  final String personId;
  final String relatedPersonId;
  final String type; // 'FATHER_OF', 'MOTHER_OF', 'CHILD_OF', 'SPOUSE_OF', 'SIBLING_OF'
  final String? createdByUserId;
  final String? createdAt;
  final Person? relatedPerson; // Populated when fetched with joins

  const Relationship({
    required this.id,
    required this.personId,
    required this.relatedPersonId,
    required this.type,
    this.createdByUserId,
    this.createdAt,
    this.relatedPerson,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      id: json['id'] as String,
      personId: json['person_id'] as String,
      relatedPersonId: json['related_person_id'] as String,
      type: json['type'] as String,
      createdByUserId: json['created_by_user_id'] as String?,
      createdAt: json['created_at'] as String?,
      relatedPerson: json['related_person'] != null
          ? Person.fromJson(json['related_person'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TreeNode {
  final Person person;
  final List<Relationship> relationships;

  const TreeNode({required this.person, required this.relationships});

  factory TreeNode.fromJson(Map<String, dynamic> json) {
    return TreeNode(
      person: Person.fromJson(json['person'] as Map<String, dynamic>),
      relationships: (json['relationships'] as List<dynamic>)
          .map((r) => Relationship.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TreeResponse {
  final List<TreeNode> nodes;
  final String rootPersonId;

  const TreeResponse({required this.nodes, required this.rootPersonId});

  factory TreeResponse.fromJson(Map<String, dynamic> json) {
    return TreeResponse(
      nodes: (json['nodes'] as List<dynamic>)
          .map((n) => TreeNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      rootPersonId: json['rootPersonId'] as String,
    );
  }
}

class MergeRequest {
  final String id;
  final String requesterUserId;
  final String targetPersonId;
  final String matchedPersonId;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final Map<String, dynamic> fieldConflicts;
  final String? createdAt;

  const MergeRequest({
    required this.id,
    required this.requesterUserId,
    required this.targetPersonId,
    required this.matchedPersonId,
    required this.status,
    required this.fieldConflicts,
    this.createdAt,
  });

  factory MergeRequest.fromJson(Map<String, dynamic> json) {
    return MergeRequest(
      id: json['id'] as String,
      requesterUserId: json['requester_user_id'] as String,
      targetPersonId: json['target_person_id'] as String,
      matchedPersonId: json['matched_person_id'] as String,
      status: json['status'] as String,
      fieldConflicts: json['field_conflicts'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] as String?,
    );
  }
}

class SearchResult {
  final Person person;
  final int depth;
  final List<String> pathNames;
  final String connectionPath;

  const SearchResult({
    required this.person,
    required this.depth,
    required this.pathNames,
    required this.connectionPath,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      person: Person.fromJson(json['person'] as Map<String, dynamic>),
      depth: json['depth'] as int,
      pathNames: (json['pathNames'] as List<dynamic>).cast<String>(),
      connectionPath: json['connectionPath'] as String,
    );
  }
}

class LifeEvent {
  final String id;
  final String personId;
  final String eventType;
  final String eventDate;
  final String? location;
  final String? description;
  final List<String>? photos;
  final String? createdByUserId;
  final String? createdAt;

  const LifeEvent({
    required this.id,
    required this.personId,
    required this.eventType,
    required this.eventDate,
    this.location,
    this.description,
    this.photos,
    this.createdByUserId,
    this.createdAt,
  });

  factory LifeEvent.fromJson(Map<String, dynamic> json) {
    return LifeEvent(
      id: json['id'] as String,
      personId: json['person_id'] as String,
      eventType: json['event_type'] as String,
      eventDate: json['event_date'] as String,
      location: json['location'] as String?,
      description: json['description'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>(),
      createdByUserId: json['created_by_user_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'person_id': personId,
      'event_type': eventType,
      'event_date': eventDate,
      'location': location,
      'description': description,
      'photos': photos,
    };
  }
}

class ForumPost {
  final String id;
  final String title;
  final String content;
  final String postType;
  final String authorUserId;
  final List<String>? tags;
  final int viewCount;
  final String? createdAt;
  final String? updatedAt;
  final List<ForumMedia>? media;
  final List<ForumComment>? comments;
  final int? likeCount;

  const ForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.postType,
    required this.authorUserId,
    this.tags,
    this.viewCount = 0,
    this.createdAt,
    this.updatedAt,
    this.media,
    this.comments,
    this.likeCount,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      postType: json['post_type'] as String,
      authorUserId: json['author_user_id'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      viewCount: json['view_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      media: (json['media'] as List<dynamic>?)
          ?.map((m) => ForumMedia.fromJson(m as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((c) => ForumComment.fromJson(c as Map<String, dynamic>))
          .toList(),
      likeCount: json['like_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'post_type': postType,
      'tags': tags,
    };
  }
}

class ForumMedia {
  final String id;
  final String postId;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final String? uploadedAt;

  const ForumMedia({
    required this.id,
    required this.postId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    this.uploadedAt,
  });

  factory ForumMedia.fromJson(Map<String, dynamic> json) {
    return ForumMedia(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      caption: json['caption'] as String?,
      uploadedAt: json['uploaded_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'caption': caption,
    };
  }
}

class ForumComment {
  final String id;
  final String postId;
  final String content;
  final String authorUserId;
  final String? parentCommentId;
  final String? createdAt;

  const ForumComment({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorUserId,
    this.parentCommentId,
    this.createdAt,
  });

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      content: json['content'] as String,
      authorUserId: json['author_user_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'content': content,
      'parent_comment_id': parentCommentId,
    };
  }
}

class Notification {
  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String message;
  final bool isRead;
  final String? relatedPersonId;
  final String? relatedPostId;
  final String? createdAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.isRead = false,
    this.relatedPersonId,
    this.relatedPostId,
    this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      relatedPersonId: json['related_person_id'] as String?,
      relatedPostId: json['related_post_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class ActivityEntry {
  final String id;
  final String personId;
  final String activityType;
  final String description;
  final String actorUserId;
  final Map<String, dynamic>? metadata;
  final String? createdAt;
  final Person? person;

  const ActivityEntry({
    required this.id,
    required this.personId,
    required this.activityType,
    required this.description,
    required this.actorUserId,
    this.metadata,
    this.createdAt,
    this.person,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      id: json['id'] as String,
      personId: json['person_id'] as String,
      activityType: json['activity_type'] as String,
      description: json['description'] as String,
      actorUserId: json['actor_user_id'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
      person: json['person'] != null 
          ? Person.fromJson(json['person'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FamilyEvent {
  final String id;
  final String title;
  final String eventType;
  final String eventDate;
  final String? description;
  final String? location;
  final String? relatedPersonId;
  final bool allDay;
  final String? recurrenceRule;
  final String? createdByUserId;
  final String? createdAt;
  final Person? person;

  const FamilyEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.eventDate,
    this.description,
    this.location,
    this.relatedPersonId,
    this.allDay = true,
    this.recurrenceRule,
    this.createdByUserId,
    this.createdAt,
    this.person,
  });

  factory FamilyEvent.fromJson(Map<String, dynamic> json) {
    return FamilyEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      eventType: json['event_type'] as String,
      eventDate: json['event_date'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      relatedPersonId: json['related_person_id'] as String?,
      allDay: json['all_day'] as bool? ?? true,
      recurrenceRule: json['recurrence_rule'] as String?,
      createdByUserId: json['created_by_user_id'] as String?,
      createdAt: json['created_at'] as String?,
      person: json['person'] != null 
          ? Person.fromJson(json['person'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'event_type': eventType,
      'event_date': eventDate,
      'description': description,
      'location': location,
      'related_person_id': relatedPersonId,
      'all_day': allDay,
      'recurrence_rule': recurrenceRule,
    };
  }
}

class PersonDocument {
  final String id;
  final String personId;
  final String documentType;
  final String documentUrl;
  final String documentName;
  final String? description;
  final String? uploadedByUserId;
  final String? uploadedAt;

  const PersonDocument({
    required this.id,
    required this.personId,
    required this.documentType,
    required this.documentUrl,
    required this.documentName,
    this.description,
    this.uploadedByUserId,
    this.uploadedAt,
  });

  factory PersonDocument.fromJson(Map<String, dynamic> json) {
    return PersonDocument(
      id: json['id'] as String,
      personId: json['person_id'] as String,
      documentType: json['document_type'] as String,
      documentUrl: json['document_url'] as String,
      documentName: json['document_name'] as String,
      description: json['description'] as String?,
      uploadedByUserId: json['uploaded_by_user_id'] as String?,
      uploadedAt: json['uploaded_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'person_id': personId,
      'document_type': documentType,
      'document_url': documentUrl,
      'document_name': documentName,
      'description': description,
    };
  }
}

/// Result of a connection path search between two persons.
class ConnectionResult {
  final bool connected;
  final List<ConnectionPath> paths; // Multiple paths
  final List<CommonAncestor> commonAncestors;
  final ConnectionStatistics statistics;
  
  // Legacy single path (for backward compatibility - uses first path)
  final List<ConnectionPerson> path;
  final List<ConnectionRelationship> relationships;
  final int depth;

  const ConnectionResult({
    required this.connected,
    required this.paths,
    required this.commonAncestors,
    required this.statistics,
    required this.path,
    required this.relationships,
    required this.depth,
  });

  factory ConnectionResult.fromJson(Map<String, dynamic> json) {
    return ConnectionResult(
      connected: json['connected'] as bool,
      paths: (json['paths'] as List<dynamic>? ?? [])
          .map((p) => ConnectionPath.fromJson(p as Map<String, dynamic>))
          .toList(),
      commonAncestors: (json['commonAncestors'] as List<dynamic>? ?? [])
          .map((a) => CommonAncestor.fromJson(a as Map<String, dynamic>))
          .toList(),
      statistics: json['statistics'] != null
          ? ConnectionStatistics.fromJson(json['statistics'] as Map<String, dynamic>)
          : const ConnectionStatistics(totalPaths: 0, shortestDistance: -1, longestDistance: -1),
      // Legacy fields
      path: (json['path'] as List<dynamic>? ?? [])
          .map((p) => ConnectionPerson.fromJson(p as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List<dynamic>? ?? [])
          .map((r) => ConnectionRelationship.fromJson(r as Map<String, dynamic>))
          .toList(),
      depth: json['depth'] as int? ?? -1,
    );
  }
}

/// A single connection path
class ConnectionPath {
  final List<ConnectionPerson> path;
  final List<ConnectionRelationship> relationships;
  final int depth;
  final CalculatedRelationship? calculatedRelationship;

  const ConnectionPath({
    required this.path,
    required this.relationships,
    required this.depth,
    this.calculatedRelationship,
  });

  factory ConnectionPath.fromJson(Map<String, dynamic> json) {
    return ConnectionPath(
      path: (json['path'] as List<dynamic>)
          .map((p) => ConnectionPerson.fromJson(p as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List<dynamic>)
          .map((r) => ConnectionRelationship.fromJson(r as Map<String, dynamic>))
          .toList(),
      depth: json['depth'] as int,
      calculatedRelationship: json['calculatedRelationship'] != null
          ? CalculatedRelationship.fromJson(json['calculatedRelationship'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Calculated natural language relationship
class CalculatedRelationship {
  final String description;
  final String category; // 'immediate', 'extended', 'distant', 'non-blood'
  final int generationsUp;
  final int generationsDown;
  final bool isBloodRelation;
  final double? geneticSimilarity; // percentage (0-50)

  const CalculatedRelationship({
    required this.description,
    required this.category,
    required this.generationsUp,
    required this.generationsDown,
    required this.isBloodRelation,
    this.geneticSimilarity,
  });

  factory CalculatedRelationship.fromJson(Map<String, dynamic> json) {
    return CalculatedRelationship(
      description: json['description'] as String,
      category: json['category'] as String,
      generationsUp: json['generationsUp'] as int,
      generationsDown: json['generationsDown'] as int,
      isBloodRelation: json['isBloodRelation'] as bool,
      geneticSimilarity: (json['geneticSimilarity'] as num?)?.toDouble(),
    );
  }
}

/// Common ancestor in the family tree
class CommonAncestor {
  final String personId;
  final String name;
  final int distanceFromA;
  final int distanceFromB;

  const CommonAncestor({
    required this.personId,
    required this.name,
    required this.distanceFromA,
    required this.distanceFromB,
  });

  int get totalDistance => distanceFromA + distanceFromB;

  factory CommonAncestor.fromJson(Map<String, dynamic> json) {
    return CommonAncestor(
      personId: json['personId'] as String,
      name: json['name'] as String,
      distanceFromA: json['distanceFromA'] as int,
      distanceFromB: json['distanceFromB'] as int,
    );
  }
}

/// Statistics about the connection
class ConnectionStatistics {
  final int totalPaths;
  final int shortestDistance;
  final int longestDistance;

  const ConnectionStatistics({
    required this.totalPaths,
    required this.shortestDistance,
    required this.longestDistance,
  });

  factory ConnectionStatistics.fromJson(Map<String, dynamic> json) {
    return ConnectionStatistics(
      totalPaths: json['totalPaths'] as int,
      shortestDistance: json['shortestDistance'] as int,
      longestDistance: json['longestDistance'] as int,
    );
  }
}

class ConnectionPerson {
  final String personId;
  final String name;
  final String gender;

  const ConnectionPerson({
    required this.personId,
    required this.name,
    required this.gender,
  });

  factory ConnectionPerson.fromJson(Map<String, dynamic> json) {
    return ConnectionPerson(
      personId: json['personId'] as String,
      name: json['name'] as String,
      gender: json['gender'] as String? ?? 'other',
    );
  }
}

class ConnectionRelationship {
  final String from;
  final String to;
  final String type;
  final String label;

  const ConnectionRelationship({
    required this.from,
    required this.to,
    required this.type,
    required this.label,
  });

  factory ConnectionRelationship.fromJson(Map<String, dynamic> json) {
    return ConnectionRelationship(
      from: json['from'] as String,
      to: json['to'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
    );
  }
}
