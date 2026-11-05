import 'dart:io';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

enum CatalogLayout {
  grid,
  list,
  gallery,
  editorial,
  mosaic,
  scroll;

  String get label => switch (this) {
        CatalogLayout.grid => 'Grille',
        CatalogLayout.list => 'Liste',
        CatalogLayout.gallery => 'Grandes photos',
        CatalogLayout.editorial => 'Éditorial',
        CatalogLayout.mosaic => 'Mosaïque',
        CatalogLayout.scroll => 'Défilement',
      };

  String get description => switch (this) {
        CatalogLayout.grid => 'Plusieurs produits visibles à la fois.',
        CatalogLayout.list => 'Une présentation compacte et facile à comparer.',
        CatalogLayout.gallery =>
          'De grandes images pour mettre les produits en valeur.',
        CatalogLayout.editorial =>
          'Un premier produit mis en avant, avec son histoire.',
        CatalogLayout.mosaic => 'Des images de tailles variées.',
        CatalogLayout.scroll =>
          'Un produit à la fois, à faire défiler sur mobile.',
      };

  static CatalogLayout fromApi(String? value) =>
      CatalogLayout.values.firstWhere(
        (layout) => layout.name == value,
        orElse: () => CatalogLayout.grid,
      );
}

class CatalogProduct {
  final int id;
  final String name;
  final String? description;
  final int? price;
  final String? photoUrl;

  const CatalogProduct({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.photoUrl,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: json['price'] == null ? null : int.parse(json['price'].toString()),
      photoUrl: json['photo_url']?.toString(),
    );
  }
}

class ProductCatalog {
  final bool enabled;
  final CatalogLayout layout;
  final String? accentColor;
  final int maxProducts;
  final int maxAllowedProducts;
  final List<CatalogProduct> products;
  final int? pendingRequestProducts;
  final String? lastRequestStatus;

  const ProductCatalog({
    required this.enabled,
    required this.layout,
    this.accentColor,
    required this.maxProducts,
    required this.maxAllowedProducts,
    required this.products,
    this.pendingRequestProducts,
    this.lastRequestStatus,
  });
}

class ProductCatalogService {
  final Dio _dio = ApiClient.dio;

  Future<ProductCatalog> load() async {
    final response = await _dio.get('/me/card/catalog');
    final data = Map<String, dynamic>.from(response.data as Map);
    final products = (data['products'] as List? ?? const [])
        .map((item) => CatalogProduct.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();

    return ProductCatalog(
      enabled: data['enabled'] == true,
      layout: CatalogLayout.fromApi(data['layout']?.toString()),
      accentColor: data['accent_color']?.toString(),
      maxProducts: int.parse(data['max_products'].toString()),
      maxAllowedProducts: int.parse(data['max_allowed_products'].toString()),
      products: products,
      pendingRequestProducts: data['pending_request'] == null
          ? null
          : int.parse(
              Map<String, dynamic>.from(
                      data['pending_request'] as Map)['requested_products']
                  .toString(),
            ),
      lastRequestStatus: data['last_request_status']?.toString(),
    );
  }

  Future<bool> setEnabled(bool enabled) async {
    final response = await _dio.put(
      '/me/card/catalog',
      data: {'enabled': enabled},
    );
    return response.data['enabled'] == true;
  }

  Future<void> setLayout(CatalogLayout layout) async {
    await _dio.put(
      '/me/card/catalog',
      data: {'layout': layout.name},
    );
  }

  Future<void> requestMoreProducts(int requestedProducts) async {
    await _dio.post(
      '/me/card/catalog/requests',
      data: {'requested_products': requestedProducts},
    );
  }

  Future<void> saveProduct({
    int? id,
    required String name,
    String? description,
    int? price,
    File? photo,
    bool removePhoto = false,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'description': description ?? '',
      'price': price?.toString() ?? '',
      'remove_photo': removePhoto ? '1' : '0',
    };
    if (photo != null) {
      data['photo'] = await MultipartFile.fromFile(
        photo.path,
        filename: photo.uri.pathSegments.last,
      );
    }

    final form = FormData.fromMap(data);
    if (id == null) {
      await _dio.post('/me/card/catalog/products', data: form);
    } else {
      form.fields.add(const MapEntry('_method', 'PATCH'));
      await _dio.post('/me/card/catalog/products/$id', data: form);
    }
  }

  Future<void> deleteProduct(int id) async {
    await _dio.delete('/me/card/catalog/products/$id');
  }
}
