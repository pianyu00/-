class Record {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String date; // yyyy-MM-dd
  final String time; // HH:mm:ss
  final String note;

  Record({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.time = '',
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'time': time,
      'note': note,
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      date: map['date'],
      time: map['time'] ?? '',
      note: map['note'] ?? '',
    );
  }
}
