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
