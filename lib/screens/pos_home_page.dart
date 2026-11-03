import 'package:flutter/material.dart';

import '../data/pos_database.dart';
import '../models/pos_models.dart';
import '../screens/tables_teams_screen.dart';

class PosHomePage extends StatefulWidget {
  const PosHomePage({super.key});

  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  final List<CartLine> _cart = [];
  late Future<List<Product>> _productsFuture;
  String _businessName = 'POS Bagan';
  String _currency = 'MMK';

  @override
  void initState() {
    super.initState();
    _productsFuture = PosDatabase.instance.getProducts();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await PosDatabase.instance.getSettings();
    if (!mounted) return;
    setState(() {
      _businessName = settings['business_name'] ?? 'POS Bagan';
      _currency = settings['currency'] ?? 'MMK';
    });
  }

  void _reloadProducts() => setState(() => _productsFuture = PosDatabase.instance.getProducts());

  int get _cartTotal => _cart.fold(0, (sum, line) => sum + line.total);

  void _addToCart(Product product) {
    setState(() {
      final index = _cart.indexWhere((line) => line.product.id == product.id);
      if (index < 0) {
        _cart.add(CartLine(product: product, quantity: 1));
      } else {
        final old = _cart[index];
        _cart[index] = CartLine(product: product, quantity: old.quantity + 1);
      }
    });
  }

  Future<void> _showProductForm() async {
    final name = TextEditingController();
    final category = TextEditingController();
    final price = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add product or service'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextField(controller: category, decoration: const InputDecoration(labelText: 'Category (optional)')),
            const SizedBox(height: 12),
            TextFormField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price ($_currency, whole units)'),
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                return parsed == null || parsed < 0 ? 'Enter a valid non-negative whole number' : null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await PosDatabase.instance.addProduct(Product(
        name: name.text.trim(),
        category: category.text.trim(),
        price: int.parse(price.text),
      ));
      _reloadProducts();
    }
    name.dispose();
    category.dispose();
    price.dispose();
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    await PosDatabase.instance.saveSale(List<CartLine>.from(_cart));
    if (!mounted) return;
    setState(_cart.clear);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale saved on this device.')));
  }

  Future<void> _showSettings() async {
    final name = TextEditingController(text: _businessName);
    final currency = TextEditingController(text: _currency);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Business settings'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Business name')),
          const SizedBox(height: 12),
          TextField(controller: currency, decoration: const InputDecoration(labelText: 'Currency code (e.g. MMK)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty && currency.text.trim().isNotEmpty) {
      await PosDatabase.instance.saveSettings(businessName: name.text.trim(), currency: currency.text.trim());
      await _loadSettings();
    }
    name.dispose();
    currency.dispose();
  }

  Future<void> _showSales() async {
    final sales = await PosDatabase.instance.getRecentSales();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent sales (saved locally)'),
        content: SizedBox(
          width: 360,
          child: sales.isEmpty
              ? const Text('No sales yet.')
              : ListView(
                  shrinkWrap: true,
                  children: sales
                      .map(
                        (sale) => ListTile(
                          title: Text('Sale #${sale.id}'),
                          subtitle: Text(sale.createdAt.toLocal().toString()),
                          trailing: Text('${sale.total} $_currency'),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_businessName),
        actions: [
          IconButton(
            tooltip: 'Tables & teams',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TablesAndTeamsScreen()),
              );
            },
            icon: const Icon(Icons.table_restaurant_outlined),
          ),
          IconButton(tooltip: 'Sales history', onPressed: _showSales, icon: const Icon(Icons.receipt_long)),
          IconButton(tooltip: 'Settings', onPressed: _showSettings, icon: const Icon(Icons.settings)),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load products: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products yet. Tap + to add a product or service.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(product.category.isEmpty ? 'Product or service' : product.category),
                leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${product.price} $_currency'),
                    IconButton(
                      tooltip: 'Add to cart',
                      onPressed: () => _addToCart(product),
                      icon: const Icon(Icons.add_shopping_cart),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showProductForm,
        tooltip: 'Add product',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _cart.isEmpty ? null : _checkout,
            icon: const Icon(Icons.point_of_sale),
            label: Text(_cart.isEmpty ? 'Cart is empty' : 'Checkout • ${_cart.length} item(s) • $_cartTotal $_currency'),
          ),
        ),
      ),
    );
  }
}
