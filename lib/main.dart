import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class Product {
  const Product(this.name, this.description, this.price, this.image);

  final String name;
  final String description;
  final num price;
  final String image;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      json['name'] as String,
      json['description'] as String,
      json['price'] as num,
      json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'image': image,
  };

  String get priceLabel => '${price.toStringAsFixed(2)} TL';
}

Future<List<Product>> loadProducts() async {
  final text = await rootBundle.loadString('assets/products.json');
  final items = jsonDecode(text) as List<dynamic>;
  return items
      .map((item) => Product.fromJson(item as Map<String, dynamic>))
      .toList();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Katalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6246A5)),
      ),
      home: const CatalogPage(),
      routes: {'/product': (_) => const ProductPage()},
    );
  }
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final Future<List<Product>> products = loadProducts();
  final List<Product> cart = [];
  String search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Katalog'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartPage(items: cart)),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text('Sepet (${cart.length})'),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: products,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Ürünler yüklenemedi.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final visible = snapshot.data!
              .where((product) => product.name.toLowerCase().contains(search))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/banner.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Center(child: Text('Teknoloji Ürünleri')),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Ürün ara',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => search = value.trim().toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(child: Text('Ürün bulunamadı.'))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                mainAxisExtent: 180,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final product = visible[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () async {
                                  final added = await Navigator.pushNamed<Product>(
                                    context,
                                    '/product',
                                    arguments: product,
                                  );
                                  if (!mounted || added == null) return;

                                  setState(() => cart.add(added));
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text('${added.name} sepete eklendi.')),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Expanded(child: ProductImage(product: product)),
                                    const SizedBox(height: 8),
                                    Text(product.name, maxLines: 1),
                                    Text(product.priceLabel),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        product.image,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.devices_other, size: 56),
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as Product;

    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Detayı')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SizedBox(height: 220, child: ProductImage(product: product)),
          const SizedBox(height: 16),
          Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(product.description),
          const SizedBox(height: 8),
          Text(product.priceLabel),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, product),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Sepete ekle'),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key, required this.items});

  final List<Product> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<num>(0, (sum, product) => sum + product.price);

    return Scaffold(
      appBar: AppBar(title: const Text('Sepet')),
      body: items.isEmpty
          ? const Center(child: Text('Sepetiniz boş.'))
          : ListView(
              children: [
                for (final product in items)
                  ListTile(
                    title: Text(product.name),
                    trailing: Text(product.priceLabel),
                  ),
                const Divider(),
                ListTile(
                  title: const Text('Toplam'),
                  trailing: Text('${total.toStringAsFixed(2)} TL'),
                ),
              ],
            ),
    );
  }
}