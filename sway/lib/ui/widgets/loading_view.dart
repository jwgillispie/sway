// lib/ui/widgets/loading_view.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured spot
            _buildShimmerContainer(context, height: 200),
            SizedBox(height: 24),
            
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmerContainer(context, width: 120, height: 24),
                _buildShimmerContainer(context, width: 80, height: 24),
              ],
            ),
            SizedBox(height: 16),
            
            // Horizontal list
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: 280,
                    margin: EdgeInsets.only(right: 16),
                    child: _buildShimmerContainer(context),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            
            // Another section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmerContainer(context, width: 150, height: 24),
                _buildShimmerContainer(context, width: 80, height: 24),
              ],
            ),
            SizedBox(height: 16),
            
            // Vertical list
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: _buildShimmerContainer(context, height: 120),
                );
              },
            ),
            
            SizedBox(height: 24),
            
            // Categories section header
            _buildShimmerContainer(context, width: 120, height: 24),
            SizedBox(height: 16),
            
            // Grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: List.generate(
                4,
                (index) => _buildShimmerContainer(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShimmerContainer(
    BuildContext context, {
    double? width,
    double height = 100,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}