import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packmate/models/review.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String parcelId;
  final String fromUid;
  final String toUid;
  final String role;

  const LeaveReviewScreen({
    super.key,
    required this.parcelId,
    required this.fromUid,
    required this.toUid,
    required this.role,
  });

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  double _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
      final review = Review(
        id: reviewRef.id,
        rating: _rating,
        text: _reviewController.text.trim(),
        fromUid: widget.fromUid,
        toUid: widget.toUid,
        parcelId: widget.parcelId,
        role: widget.role,
        createdAt: DateTime.now(),
      );

      final profileRef = FirebaseFirestore.instance.collection('profiles').doc(widget.toUid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final profileSnapshot = await transaction.get(profileRef);

        if (!profileSnapshot.exists) {
          // Create profile if it doesn't exist
          transaction.set(profileRef, {
            'ratingCount': 1,
            'totalRating': _rating,
            'averageRating': _rating,
          });
        } else {
          final currentRatingCount = profileSnapshot.data()!['ratingCount'] ?? 0;
          final currentTotalRating = profileSnapshot.data()!['totalRating'] ?? 0.0;

          final newRatingCount = currentRatingCount + 1;
          final newTotalRating = currentTotalRating + _rating;
          final newAverageRating = newTotalRating / newRatingCount;

          transaction.update(profileRef, {
            'ratingCount': newRatingCount,
            'totalRating': newTotalRating,
            'averageRating': newAverageRating,
          });
        }

        transaction.set(reviewRef, review.toMap());
      });

      // Mark this user as having reviewed this parcel interaction
      final parcelRef = FirebaseFirestore.instance.collection('parcels').doc(widget.parcelId);
      await parcelRef.update({
        'reviewsGiven.${widget.fromUid}': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text('Review:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _reviewController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Share your experience...',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
