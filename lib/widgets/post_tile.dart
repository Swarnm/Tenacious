import 'package:flutter/material.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/promoposts_screen.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/promopost.dart';

class PostTile extends StatelessWidget {
final Post post;

PostTile(this.post);

 showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          userId: post.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}

class PromoPostsTile extends StatelessWidget {
final PromoPosts promoposts;

PromoPostsTile(this.promoposts);

showPromoPosts(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromoPostsScreen(
          promopostsId: promoposts.promopostsId,
          userId: promoposts.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPromoPosts(context),
      child: cachedNetworkImage(promoposts.promomediaUrl),
    );
  }
}
