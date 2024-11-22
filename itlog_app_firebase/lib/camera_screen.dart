import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/intl.dart'; // For date formatting

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late Future<List<Map<String, dynamic>>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = _fetchImages(); // Fetch images on initialization
  }

  Future<List<Map<String, dynamic>>> _fetchImages() async {
    try {
      final storageRef = FirebaseStorage.instance.ref('images');
      ListResult result = await storageRef.listAll();
      List<Map<String, dynamic>> imageDetails = [];

      for (var ref in result.items) {
        try {
          String url = await ref.getDownloadURL();
          final metadata = await ref.getMetadata();
          imageDetails.add({
            'url': url,
            'filename': ref.name,
            'uploadDate': metadata.timeCreated, // Directly use DateTime
          });
        } catch (e) {
          print('Error getting details for ${ref.fullPath}: $e');
        }
      }

      // Sort images by upload date in descending order
      imageDetails.sort((a, b) => b['uploadDate'].compareTo(a['uploadDate']));

      return imageDetails;
    } catch (e) {
      print('Error fetching images: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _imagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No images found.'));
          } else {
            List<Map<String, dynamic>> imageDetails = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1, // Ensure the images are square
              ),
              itemCount: imageDetails.length,
              itemBuilder: (context, index) {
                final details = imageDetails[index];
                final url = details['url'];
                final filename = details['filename'];
                final uploadDate = details['uploadDate'] as DateTime;

                // Format the date as needed
                final formattedDate = DateFormat('yyyy-MM-dd').format(uploadDate);

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Scaffold(
                        backgroundColor: Colors.black,
                        body: Stack(
                          children: [
                            PhotoViewGallery.builder(
                              itemCount: imageDetails.length,
                              builder: (context, index) {
                                final details = imageDetails[index];
                                return PhotoViewGalleryPageOptions(
                                  imageProvider: CachedNetworkImageProvider(details['url']),
                                  minScale: PhotoViewComputedScale.contained,
                                  maxScale: PhotoViewComputedScale.covered * 2,
                                );
                              },
                              scrollPhysics: BouncingScrollPhysics(),
                              backgroundDecoration: BoxDecoration(color: Colors.black),
                              pageController: PageController(initialPage: imageDetails.indexOf(details)),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(url),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black54, Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '$filename\n$formattedDate',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}