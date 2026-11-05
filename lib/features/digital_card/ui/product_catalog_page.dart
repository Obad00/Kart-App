import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_error.dart';
import '../../../core/ui/feedback/feedback_overlay.dart';
import '../data/product_catalog_service.dart';

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  final _service = ProductCatalogService();
  ProductCatalog? _catalog;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _visibilitySaving = false;
  bool _requesting = false;
  bool _layoutSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await _service.load();
      if (mounted) setState(() => _catalog = catalog);
    } catch (error) {
      if (mounted) setState(() => _error = getErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setEnabled(bool enabled) async {
    if (_catalog == null) return;
    setState(() => _visibilitySaving = true);
    try {
      final saved = await _service.setEnabled(enabled);
      if (mounted) {
        setState(() => _catalog = ProductCatalog(
              enabled: saved,
              layout: _catalog!.layout,
              accentColor: _catalog!.accentColor,
              maxProducts: _catalog!.maxProducts,
              maxAllowedProducts: _catalog!.maxAllowedProducts,
              products: _catalog!.products,
              pendingRequestProducts: _catalog!.pendingRequestProducts,
              lastRequestStatus: _catalog!.lastRequestStatus,
            ));
      }
    } catch (error) {
      if (!mounted) return;
      FeedbackOverlay.showError(
        context,
        title: 'Publication non modifiée',
        subtitle: getErrorMessage(error),
      );
    } finally {
      if (mounted) setState(() => _visibilitySaving = false);
    }
  }

  Future<void> _setLayout(CatalogLayout layout) async {
    final catalog = _catalog;
    if (catalog == null || catalog.layout == layout || _layoutSaving) return;

    setState(() => _layoutSaving = true);
    try {
      await _service.setLayout(layout);
      if (mounted) {
        setState(() => _catalog = ProductCatalog(
              enabled: catalog.enabled,
              layout: layout,
              accentColor: catalog.accentColor,
              maxProducts: catalog.maxProducts,
              maxAllowedProducts: catalog.maxAllowedProducts,
              products: catalog.products,
              pendingRequestProducts: catalog.pendingRequestProducts,
              lastRequestStatus: catalog.lastRequestStatus,
            ));
        FeedbackOverlay.showSuccess(
          context,
          title: 'Disposition enregistrée',
          subtitle: 'Votre catalogue utilisera « ${layout.label} ».',
        );
      }
    } catch (error) {
      if (mounted) {
        FeedbackOverlay.showError(
          context,
          title: 'Disposition non modifiée',
          subtitle: getErrorMessage(error),
        );
      }
    } finally {
      if (mounted) setState(() => _layoutSaving = false);
    }
  }

  Future<void> _editProduct([CatalogProduct? product]) async {
    final draft = await showDialog<_ProductDraft>(
      context: context,
      builder: (_) => _ProductEditorDialog(product: product),
    );
    if (draft == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await _service.saveProduct(
        id: product?.id,
        name: draft.name,
        description: draft.description,
        price: draft.price,
        photo: draft.photo,
        removePhoto: draft.removePhoto,
      );
      await _load();
      if (mounted) {
        FeedbackOverlay.showSuccess(
          context,
          title: 'Catalogue mis à jour',
          subtitle: product == null ? 'Produit ajouté.' : 'Produit modifié.',
        );
      }
    } catch (error) {
      if (mounted) {
        FeedbackOverlay.showError(
          context,
          title: 'Enregistrement impossible',
          subtitle: getErrorMessage(error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteProduct(CatalogProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce produit ?'),
        content: Text('« ${product.name} » sera supprimé de votre catalogue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteProduct(product.id);
      await _load();
      if (mounted) {
        FeedbackOverlay.showSuccess(
          context,
          title: 'Produit retiré',
          subtitle: product.name,
        );
      }
    } catch (error) {
      if (mounted) {
        FeedbackOverlay.showError(
          context,
          title: 'Suppression impossible',
          subtitle: getErrorMessage(error),
        );
      }
    }
  }

  Future<void> _requestMoreProducts() async {
    final catalog = _catalog;
    if (catalog == null ||
        !catalog.enabled ||
        catalog.pendingRequestProducts != null) {
      return;
    }

    final maxRequest = catalog.maxAllowedProducts - catalog.maxProducts;
    if (maxRequest <= 0) return;

    final controller = TextEditingController(text: '1');
    final requestedProducts = await showDialog<int>(
      context: context,
      builder: (context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Demander des places'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vous pouvez demander jusqu’à $maxRequest place(s).'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Nombre de places',
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  final count = int.tryParse(controller.text);
                  if (count == null || count < 1 || count > maxRequest) {
                    setDialogState(() {
                      errorText =
                          'Choisissez un nombre entre 1 et $maxRequest.';
                    });
                    return;
                  }
                  Navigator.pop(context, count);
                },
                child: const Text('Envoyer la demande'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (requestedProducts == null || !mounted) return;

    setState(() => _requesting = true);
    try {
      await _service.requestMoreProducts(requestedProducts);
      await _load();
      if (mounted) {
        FeedbackOverlay.showSuccess(
          context,
          title: 'Demande envoyée',
          subtitle: 'L’équipe KART vous informera de la suite.',
        );
      }
    } catch (error) {
      if (mounted) {
        FeedbackOverlay.showError(
          context,
          title: 'Demande non envoyée',
          subtitle: getErrorMessage(error),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final catalog = _catalog;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon catalogue')),
      body: _loading && catalog == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && catalog == null
              ? _ErrorState(message: _error!, onRetry: _load)
              : catalog == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        children: [
                          Text(
                            'Présentez vos produits sur votre carte KART.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez jusqu’à 20 produits au total. Votre catalogue reste privé tant que vous ne l’activez pas. Les prix affichés sont indicatifs : KART ne prend pas de commande et ne traite aucun paiement.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.45,
                                ),
                          ),
                          const SizedBox(height: 18),
                          Card(
                            child: SwitchListTile.adaptive(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              title: const Text('Afficher mon catalogue'),
                              subtitle: Text(
                                catalog.enabled
                                    ? 'Visible sur votre carte publique'
                                    : 'Désactivé : vos produits restent privés',
                              ),
                              value: catalog.enabled,
                              onChanged: _saving || _visibilitySaving
                                  ? null
                                  : _setEnabled,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Présentation du catalogue',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choisissez une disposition. Elle reprendra la couleur de votre carte.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                                  constraints.maxWidth < 380 ? 1 : 2;
                              return GridView.count(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: columns == 1 ? 2.2 : 1.12,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: CatalogLayout.values
                                    .map(
                                      (layout) => _CatalogLayoutChoice(
                                        layout: layout,
                                        selected: catalog.layout == layout,
                                        saving: _layoutSaving,
                                        accent: _catalogAccent(
                                          catalog.accentColor,
                                          colors.primary,
                                        ),
                                        onTap: () => _setLayout(layout),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Produits (${catalog.products.length}/${catalog.maxProducts})',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              if (catalog.products.length < catalog.maxProducts)
                                FilledButton.tonalIcon(
                                  onPressed:
                                      _saving ? null : () => _editProduct(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ajouter'),
                                ),
                            ],
                          ),
                          if (catalog.pendingRequestProducts != null) ...[
                            const SizedBox(height: 12),
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.hourglass_top),
                                title: const Text('Demande en cours'),
                                subtitle: Text(
                                  '${catalog.pendingRequestProducts} place(s) demandée(s). L’équipe KART vous informera de la suite.',
                                ),
                              ),
                            ),
                          ] else if (catalog.enabled &&
                              catalog.lastRequestStatus == 'rejected') ...[
                            const SizedBox(height: 12),
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.info_outline),
                                title: const Text('Demande non acceptée'),
                                subtitle: const Text(
                                  'Vous pouvez envoyer une nouvelle demande.',
                                ),
                              ),
                            ),
                          ] else if (catalog.enabled &&
                              catalog.maxProducts <
                                  catalog.maxAllowedProducts) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _requesting ? null : _requestMoreProducts,
                                icon: _requesting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.add_circle_outline),
                                label: const Text('Demander des places'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (catalog.products.isEmpty)
                            _EmptyCatalog(onAdd: () => _editProduct())
                          else
                            ...catalog.products.map(
                              (product) => _ProductTile(
                                product: product,
                                onEdit: () => _editProduct(product),
                                onDelete: () => _deleteProduct(product),
                              ),
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(color: colors.error),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

Color _catalogAccent(String? value, Color fallback) {
  if (value == null ||
      !RegExp(r'^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$').hasMatch(value)) {
    return fallback;
  }
  final hex = value.substring(1);
  final normalized = hex.length == 3
      ? hex.split('').map((digit) => '$digit$digit').join()
      : hex;
  return Color(int.parse('FF$normalized', radix: 16));
}

class _CatalogLayoutChoice extends StatelessWidget {
  final CatalogLayout layout;
  final bool selected;
  final bool saving;
  final Color accent;
  final VoidCallback onTap;

  const _CatalogLayoutChoice({
    required this.layout,
    required this.selected,
    required this.saving,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${layout.label}. ${layout.description}',
      child: InkWell(
        onTap: saving ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.1) : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child:
                            _LayoutMiniature(layout: layout, accent: accent)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            layout.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle, size: 18, color: accent),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      layout.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutMiniature extends StatelessWidget {
  final CatalogLayout layout;
  final Color accent;

  const _LayoutMiniature({required this.layout, required this.accent});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget image({int flex = 1}) => Expanded(
          flex: flex,
          child: Container(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
    Widget line({double width = 24}) => Container(
          width: width,
          height: 4,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(3),
          ),
        );

    switch (layout) {
      case CatalogLayout.grid:
        return Row(
          children: [
            image(),
            const SizedBox(width: 6),
            image(),
          ],
        );
      case CatalogLayout.list:
        return Column(
          children: [
            for (var index = 0; index < 2; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: index == 0 ? 5 : 0),
                  child: Row(
                    children: [
                      image(),
                      const SizedBox(width: 7),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [line(width: 42), line(width: 26)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      case CatalogLayout.gallery:
        return Column(
          children: [
            image(),
            const SizedBox(height: 5),
            Align(alignment: Alignment.centerLeft, child: line(width: 50)),
          ],
        );
      case CatalogLayout.editorial:
        return Row(
          children: [
            image(flex: 3),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [line(width: 38), line(width: 25), line(width: 46)],
              ),
            ),
          ],
        );
      case CatalogLayout.mosaic:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  image(flex: 2),
                  const SizedBox(width: 5),
                  image(),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Row(
                children: [
                  image(),
                  const SizedBox(width: 5),
                  image(flex: 2),
                ],
              ),
            ),
          ],
        );
      case CatalogLayout.scroll:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                height: 22,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: line(width: 38),
              ),
            ),
          ],
        );
    }
  }
}

class _ProductTile extends StatelessWidget {
  final CatalogProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        leading: _ProductImage(url: product.photoUrl, size: 56),
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (product.price != null) _formatPrice(product.price!),
            if (product.description?.isNotEmpty == true) product.description!,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  final double size;

  const _ProductImage({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? ColoredBox(
                color: color.primaryContainer,
                child: Icon(Icons.inventory_2_outlined, color: color.primary),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: color.primaryContainer,
                  child: Icon(Icons.inventory_2_outlined, color: color.primary),
                ),
              ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyCatalog({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 32, color: colors.primary),
          const SizedBox(height: 10),
          const Text('Votre catalogue est vide'),
          const SizedBox(height: 4),
          Text(
            'Ajoutez un produit pour commencer.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
}

class _ProductDraft {
  final String name;
  final String? description;
  final int? price;
  final File? photo;
  final bool removePhoto;

  const _ProductDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.photo,
    required this.removePhoto,
  });
}

class _ProductEditorDialog extends StatefulWidget {
  final CatalogProduct? product;

  const _ProductEditorDialog({this.product});

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  File? _photo;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?.name ?? '');
    _description =
        TextEditingController(text: widget.product?.description ?? '');
    _price = TextEditingController(
      text: widget.product?.price?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image != null && mounted) {
      setState(() {
        _photo = File(image.path);
        _removePhoto = false;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ProductDraft(
        name: _name.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        price:
            _price.text.trim().isEmpty ? null : int.parse(_price.text.trim()),
        photo: _photo,
        removePhoto: _removePhoto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return AlertDialog(
      title:
          Text(product == null ? 'Ajouter un produit' : 'Modifier le produit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Nom du produit'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Obligatoire'
                    : null,
              ),
              TextFormField(
                controller: _description,
                maxLength: 2000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (facultative)',
                ),
              ),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Prix indicatif en FCFA (facultatif)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final price = int.tryParse(value);
                  if (price == null || price > 1000000000) {
                    return 'Saisissez un montant valide.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_photo != null ||
                  (product?.photoUrl != null && !_removePhoto))
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _photo != null
                      ? Image.file(_photo!,
                          width: 112, height: 112, fit: BoxFit.cover)
                      : Image.network(
                          product!.photoUrl!,
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(_photo == null && product?.photoUrl == null
                        ? 'Ajouter une photo'
                        : 'Changer la photo'),
                  ),
                  if (_photo != null || product?.photoUrl != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _photo = null;
                        _removePhoto = true;
                      }),
                      child: const Text('Retirer'),
                    ),
                ],
              ),
              Text(
                'JPG, PNG ou WebP · 5 Mo maximum',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

String _formatPrice(int price) =>
    '${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';
