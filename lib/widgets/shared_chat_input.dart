import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_export.dart';
import '../core/services/image_service.dart';

class SharedChatInput extends StatefulWidget {
  final TextEditingController textController;
  final String hintText;
  final bool showImageButton;
  final bool showVoiceButton;
  final bool isEnabled;
  final int maxLines;
  final Function(String)? onSend;
  final Function(List<File>)? onImagesSelected;
  final VoidCallback? onVoicePressed;
  final Function(String)? onChanged;
  final List<File> selectedImages;

  const SharedChatInput({
    Key? key,
    required this.textController,
    this.hintText = "How can I help you?",
    this.showImageButton = true,
    this.showVoiceButton = true,
    this.isEnabled = true,
    this.maxLines = 3,
    this.onSend,
    this.onImagesSelected,
    this.onVoicePressed,
    this.onChanged,
    this.selectedImages = const [],
  }) : super(key: key);

  @override
  State<SharedChatInput> createState() => _SharedChatInputState();
}

class _SharedChatInputState extends State<SharedChatInput> {
  List<File> _localSelectedImages = [];

  @override
  void initState() {
    super.initState();
    _localSelectedImages = List.from(widget.selectedImages);
  }

  @override
  void didUpdateWidget(SharedChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedImages != oldWidget.selectedImages) {
      setState(() {
        _localSelectedImages = List.from(widget.selectedImages);
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImageService.pickImagesFromGallery();
      if (images.isNotEmpty) {
        setState(() {
          _localSelectedImages.addAll(images);
        });
        widget.onImagesSelected?.call(_localSelectedImages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _localSelectedImages.removeAt(index);
    });
    widget.onImagesSelected?.call(_localSelectedImages);
  }

  void _handleSend() {
    final text = widget.textController.text.trim();
    if (text.isNotEmpty || _localSelectedImages.isNotEmpty) {
      widget.onSend?.call(text);
      // Clear images after sending
      setState(() {
        _localSelectedImages.clear();
      });
      widget.onImagesSelected?.call(_localSelectedImages);
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.h,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.h),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Select Images',
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: appTheme.blackCustom,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImages();
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60.h,
            height: 60.h,
            decoration: BoxDecoration(
              color: appTheme.colorFF0373.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.h),
            ),
            child: Icon(
              icon,
              color: appTheme.colorFF0373,
              size: 30.h,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: appTheme.blackCustom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnails() {
    return Container(
      padding: EdgeInsets.all(8.h),
      child: Wrap(
        spacing: 8.h,
        runSpacing: 8.h,
        children: _localSelectedImages.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.h),
                child: Image.file(
                  image,
                  width: 40.h,
                  height: 40.h,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -2.h,
                right: -2.h,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    width: 20.h,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.h),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12.h,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.whiteCustom,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: appTheme.colorFFE9E9),
        boxShadow: [
          BoxShadow(
            color: appTheme.blackCustom.withOpacity(0.05),
            blurRadius: 4.h,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selected images thumbnails
          if (_localSelectedImages.isNotEmpty) _buildImageThumbnails(),

          // Text area
          Padding(
            padding: EdgeInsets.only(
              left: 8.h,
              right: 8.h,
              top: 6.h,
              bottom: 2.h,
            ),
            child: TextField(
              controller: widget.textController,
              enabled: widget.isEnabled,
              minLines: 1,
              maxLines: widget.maxLines,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16.fSize,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10.h,
                  horizontal: 8.h,
                ),
              ),
              style: TextStyle(
                fontSize: 16.fSize,
                fontFamily: 'Poppins',
                color: appTheme.blackCustom,
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => _handleSend(),
            ),
          ),

          // Toolbar buttons
          Padding(
            padding: EdgeInsets.only(
              left: 4.h,
              right: 4.h,
              bottom: 4.h,
              top: 2.h,
            ),
            child: Row(
              children: [
                // Image button
                if (widget.showImageButton)
                  IconButton(
                    icon: Icon(
                      Icons.add_a_photo_outlined,
                      color: widget.isEnabled
                          ? appTheme.colorFF0373
                          : Colors.grey[400],
                    ),
                    onPressed:
                        widget.isEnabled ? _showImagePickerBottomSheet : null,
                  ),

                // Voice button
                if (widget.showVoiceButton)
                  IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: widget.isEnabled
                          ? appTheme.colorFF0373
                          : Colors.grey[400],
                    ),
                    onPressed: widget.isEnabled ? widget.onVoicePressed : null,
                  ),

                const Spacer(),

                // Send button
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: widget.isEnabled
                        ? appTheme.colorFF0373
                        : Colors.grey[400],
                  ),
                  onPressed: widget.isEnabled ? _handleSend : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
