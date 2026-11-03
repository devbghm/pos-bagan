class Product {
  const Product({this.id, required this.name, required this.category, required this.price});

  final int? id;
  final String name;
  final String category;
  final int price;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'price': price,
      };

  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as int,
        name: map['name'] as String,
        category: map['category'] as String,
        price: map['price'] as int,
      );
}

class CartLine {
  const CartLine({required this.product, required this.quantity});
  final Product product;
  final int quantity;
  int get total => product.price * quantity;
}

class SaleSummary {
  const SaleSummary({required this.id, required this.total, required this.createdAt});
  final int id;
  final int total;
  final DateTime createdAt;

  factory SaleSummary.fromMap(Map<String, Object?> map) => SaleSummary(
        id: map['id'] as int,
        total: map['total'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class PosTable {
  const PosTable({this.id, required this.label, this.teamName = '', this.occupied = false});

  final int? id;
  final String label;
  final String teamName;
  final bool occupied;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'label': label,
        'team_name': teamName,
        'occupied': occupied ? 1 : 0,
      };

  factory PosTable.fromMap(Map<String, Object?> map) => PosTable(
        id: map['id'] as int,
        label: map['label'] as String,
        teamName: map['team_name'] as String? ?? '',
        occupied: (map['occupied'] as int?) == 1,
      );
}

class PosTeam {
  const PosTeam({this.id, required this.name, required this.color});

  final int? id;
  final String name;
  final String color;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'color': color,
      };

  factory PosTeam.fromMap(Map<String, Object?> map) => PosTeam(
        id: map['id'] as int,
        name: map['name'] as String,
        color: map['color'] as String? ?? '#8A4B18',
      );
}
