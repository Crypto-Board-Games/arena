import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class RankingEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int elo;
  final int wins;
  final int losses;

  const RankingEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.elo,
    required this.wins,
    required this.losses,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      rank: json['rank'] as int,
      userId: (json['userId'] as String).toString(),
      displayName: json['displayName'] as String,
      elo: json['elo'] as int,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
    );
  }
}

class RankingResponse {
  final List<RankingEntry> rankings;
  final int myRank;

  const RankingResponse({required this.rankings, required this.myRank});

  factory RankingResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['rankings'] as List<dynamic>)
        .map((e) => RankingEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return RankingResponse(rankings: list, myRank: json['myRank'] as int);
  }
}

class RankingService {
  Future<RankingResponse> fetchRankings(String token, {int limit = 100}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.rankings}?limit=$limit',
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Rankings request failed: ${response.statusCode} ${response.body}',
      );
    }

    return RankingResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
