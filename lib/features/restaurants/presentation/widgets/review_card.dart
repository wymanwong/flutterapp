import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../domain/models/review.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isOwner;
  final VoidCallback? onHelpfulPressed;
  final VoidCallback? onReportPressed;
  final VoidCallback? onReplyPressed;
  
  const ReviewCard({
    Key? key,
    required this.review,
    this.isOwner = false,
    this.onHelpfulPressed,
    this.onReportPressed,
    this.onReplyPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User avatar
                CircleAvatar(
                  backgroundImage: review.userImageUrl != null 
                    ? NetworkImage(review.userImageUrl!) 
                    : null,
                  child: review.userImageUrl == null 
                    ? Text(review.userName.isNotEmpty 
                        ? review.userName[0].toUpperCase() 
                        : '?') 
                    : null,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                
                // User name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: theme.textTheme.titleMedium,
                          ),
                          if (review.isVerifiedVisit)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.verified_user,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        dateFormat.format(review.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                // Rating
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: theme.colorScheme.primary,
                  ),
                  itemCount: 5,
                  itemSize: 18,
                ),
              ],
            ),
            
            // Review content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(review.comment),
            ),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Helpful button
                TextButton.icon(
                  onPressed: onHelpfulPressed,
                  icon: Icon(
                    review.helpfulVotes.isNotEmpty
                        ? Icons.thumb_up
                        : Icons.thumb_up_alt_outlined,
                    size: 16,
                  ),
                  label: Text(
                    review.helpfulVotes.isNotEmpty
                        ? '${review.helpfulVotes.length} Helpful'
                        : 'Helpful',
                    style: theme.textTheme.labelSmall,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                
                // Report/Reply actions
                isOwner
                    ? TextButton.icon(
                        onPressed: onReplyPressed,
                        icon: const Icon(Icons.reply, size: 16),
                        label: Text(
                          'Reply',
                          style: theme.textTheme.labelSmall,
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: onReportPressed,
                        icon: const Icon(Icons.flag_outlined, size: 16),
                        label: Text(
                          'Report',
                          style: theme.textTheme.labelSmall,
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 