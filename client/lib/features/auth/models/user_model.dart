class UserModel {
  final String id;
  final String? email;
  final String displayName;
  final int elo;
  final int wins;
  final int losses;

  const UserModel({
    required this.id,
    this.email,
    required this.displayName,
    required this.elo,
    required this.wins,
    required this.losses,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String,
      elo: json['elo'] as int,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'elo': elo,
      'wins': wins,
      'losses': losses,
    };
  }

  int get totalGames => wins + losses;
  
  double get winRate => totalGames > 0 ? wins / totalGames * 100 : 0;
}
