/// Data models for the MyFamilyTree app.

class Person {
  final String id;
  final String name;
  final String? dateOfBirth;
  final String gender; // 'male', 'female', 'other'
  final String? photoUrl;
  final String phone;
  final String? email;
  final String? occupation;
  final String? community;
  final String? city;
  final String? state;
  final String maritalStatus; // 'single', 'married', 'divorced', 'widowed'
  final String? weddingDate;
  final String? createdByUserId;
  final String? authUserId;
  final bool verified;
  final String? createdAt;
  final String? updatedAt;

  const Person({
    required this.id,
    required this.name,
    this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    required this.phone,
    this.email,
    this.occupation,
    this.community,
    this.city,
    this.state,
    this.maritalStatus = 'single',
    this.weddingDate,
    this.createdByUserId,
    this.authUserId,
    this.verified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String,
      photoUrl: json['photo_url'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      occupation: json['occupation'] as String?,
      community: json['community'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      maritalStatus: json['marital_status'] as String? ?? 'single',
      weddingDate: json['wedding_date'] as String?,
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
      'name': name,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'photo_url': photoUrl,
      'phone': phone,
      'email': email,
      'occupation': occupation,
      'community': community,
      'city': city,
      'state': state,
      'marital_status': maritalStatus,
      'wedding_date': weddingDate,
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
    String? dateOfBirth,
    String? gender,
    String? photoUrl,
    String? phone,
    String? email,
    String? occupation,
    String? community,
    String? city,
    String? state,
    String? maritalStatus,
    String? weddingDate,
    bool? verified,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      occupation: occupation ?? this.occupation,
      community: community ?? this.community,
      city: city ?? this.city,
      state: state ?? this.state,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      weddingDate: weddingDate ?? this.weddingDate,
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
