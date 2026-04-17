class SessionModel {
  final String sessionId;
  final String tableId;

  SessionModel({
    required this.sessionId,
    required this.tableId,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['session_id'],
      tableId: json['table_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'table_id': tableId,
    };
  }
}