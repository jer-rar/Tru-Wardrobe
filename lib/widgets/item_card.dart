import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'color_swatch.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['thumbnail_url'] ?? item['image_url'];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(kCardColor),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.toString().isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(color: Color(kPlaceholderColor)),
                      errorWidget: (_, _, _) => const ColoredBox(
                        color: Color(kPlaceholderColor),
                        child: Icon(Icons.checkroom, color: Colors.white24, size: 32),
                      ),
                    )
                  else
                    const ColoredBox(
                      color: Color(kPlaceholderColor),
                      child: Icon(Icons.checkroom, color: Colors.white24, size: 32),
                    ),
                  if (item['favorite'] == true)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.favorite, color: Color(kAccentColor), size: 18),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ColorSwatchDot(colorName: item['color_primary']?.toString()),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['category']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
