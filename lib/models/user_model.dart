class UserModel {
  final String uid;
  final String name;
  final String designation;
  final String company;
  final String phone;
  final String email;
  final String linkedin;
  final String website;
  final String bio;
  final String profileImage;

  UserModel({
    required this.uid,
    required this.name,
    required this.designation,
    required this.company,
    required this.phone,
    required this.email,
    required this.linkedin,
    required this.website,
    required this.bio,
    required this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'designation': designation,
      'company': company,
      'phone': phone,
      'email': email,
      'linkedin': linkedin,
      'website': website,
      'bio': bio,
      'profileImage': profileImage,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      designation: map['designation'] ?? '',
      company: map['company'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      linkedin: map['linkedin'] ?? '',
      website: map['website'] ?? '',
      bio: map['bio'] ?? '',
      profileImage: map['profileImage'] ?? '',
    );
  }
}