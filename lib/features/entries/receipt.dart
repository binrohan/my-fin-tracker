import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../ui/forms.dart';

/// Asks for a photo from the camera or the gallery and keeps a copy in the
/// receipts folder. Returns the new file name, or null if cancelled.
Future<String?> takeReceiptPhoto(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  // Small enough to keep backups light, sharp enough to read a receipt.
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 75,
  );
  if (picked == null) return null;
  final store = await ref.read(receiptStoreProvider.future);
  return store.add(File(picked.path));
}

/// A receipt photo, cropped to [height]; tap to see it full screen.
class ReceiptThumb extends ConsumerWidget {
  const ReceiptThumb({super.key, required this.name, this.height = 140});

  final String name;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(receiptStoreProvider).value;
    final status = StatusColors.of(context);
    final missing = Container(
      height: height,
      alignment: Alignment.center,
      color: status.warnSoft,
      child: Text('Photo not found', style: TextStyle(color: status.warn)),
    );
    if (store == null) return SizedBox(height: height);
    final file = store.file(name);
    if (!file.existsSync()) return missing;
    return Semantics(
      button: true,
      label: 'Receipt photo. Open full screen',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute<void>(builder: (_) => _ReceiptViewer(file: file))),
          child: Image.file(
            file,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheHeight: (height * MediaQuery.devicePixelRatioOf(context)).round(),
            errorBuilder: (_, _, _) => missing,
          ),
        ),
      ),
    );
  }
}

class _ReceiptViewer extends StatelessWidget {
  const _ReceiptViewer({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Receipt'),
    ),
    body: InteractiveViewer(maxScale: 5, child: Center(child: Image.file(file))),
  );
}

/// The receipt part of the entry details sheet: the photo with Replace and
/// Remove, or a button to add one.
class EntryReceipt extends ConsumerWidget {
  const EntryReceipt({super.key, required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repositoryProvider);
    Future<void> attach() async {
      final name = await takeReceiptPhoto(context, ref);
      if (name == null) return;
      final old = entry.receipt;
      await repo.setReceipt(entry.id, name);
      await (await ref.read(receiptStoreProvider.future)).remove(old);
    }

    final name = entry.receipt;
    if (name == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: attach,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Add receipt photo'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        ReceiptThumb(name: name),
        Row(
          children: [
            TextButton.icon(
              onPressed: attach,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Replace'),
            ),
            TextButton.icon(
              onPressed: () async {
                if (!await confirm(
                  context,
                  title: 'Remove the receipt photo?',
                  body: 'The entry stays; only the photo is deleted.',
                  action: 'Remove',
                  destructive: true,
                )) {
                  return;
                }
                await repo.setReceipt(entry.id, null);
                await (await ref.read(receiptStoreProvider.future)).remove(name);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }
}
