import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:transparent_image/transparent_image.dart';

class FadeInNetworkImage extends StatelessWidget {
  final String image;
  final BoxFit? fit;

  const FadeInNetworkImage(this.image, {super.key, this.fit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.black)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fade(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            ),
        FadeInImage.memoryNetwork(
          placeholder: kTransparentImage,
          image: image,
          fit: fit,
        ),
      ],
    );
  }
}
