class GoogleUser {
  final String? id;
  final String? email;
  final bool verifiedEmail;
  final String? name;
  final String? givenName;
  final String? familyName;
  final String? picture;
  final String? locale;
  final String? deviceId;

  const GoogleUser({
    this.id,
    this.email,
    this.verifiedEmail = false,
    this.name,
    this.givenName,
    this.familyName,
    this.picture,
    this.locale,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'verified_email': verifiedEmail,
      'name': name,
      'given_name': givenName,
      'family_name': familyName,
      'picture': picture,
      'locale': locale,
      'device_id': deviceId,
    };
  }

  factory GoogleUser.fromJson(Map<String, dynamic> json) {
    return GoogleUser(
      id: json['id'] as String?,
      email: json['email'] as String?,
      verifiedEmail: json['verified_email'] as bool? ?? false,
      name: json['name'] as String?,
      givenName: json['given_name'] as String?,
      familyName: json['family_name'] as String?,
      picture: json['picture'] as String?,
      locale: json['locale'] as String?,
      deviceId: json['device_id'] as String?,
    );
  }
}
