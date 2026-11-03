import 'package:flutter_test/flutter_test.dart';
import 'package:pos_bagan/models/pos_models.dart';

void main() {
  group('CartLine', () {
    test('calculates line total from whole-unit price and quantity', () {
      const product = Product(id: 1, name: 'Tea', category: 'Drinks', price: 1200);
      const line = CartLine(product: product, quantity: 3);
      expect(line.total, 3600);
    });
  });
}
