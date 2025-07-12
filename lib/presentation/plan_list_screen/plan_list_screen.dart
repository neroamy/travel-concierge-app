import 'package:flutter/material.dart';
import '../../core/services/travel_concierge_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/app_export.dart';
import '../travel_exploration_screen/widgets/shared_bottom_nav_bar.dart';

class PlanListScreen extends StatefulWidget {
  const PlanListScreen({super.key});

  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  List<PlanSummaryModel> _plans = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() {
      _isLoading = true;
    });
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null && user.id.isNotEmpty) {
      final plans = await TravelConciergeService().getUserPlans(user.id);
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } else {
      setState(() {
        _plans = [];
        _isLoading = false;
      });
    }
  }

  int _bottomNavIndex = 1; // Plan List tab

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 247, 245, 245), // Gray background
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
              color: appTheme.whiteCustom,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.arrow_back,
                        size: 28.h, color: appTheme.blackCustom),
                  ),
                  SizedBox(width: 16.h),
                  Text(
                    'Plan List',
                    style: TextStyle(
                      fontSize: 20.fSize,
                      fontWeight: FontWeight.w600,
                      color: appTheme.blackCustom,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _plans.isEmpty
                ? const Center(child: Text('No plans found'))
                : ListView.separated(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.h),
                    itemCount: _plans.length,
                    separatorBuilder: (context, i) => SizedBox(height: 20.h),
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return _buildPlanListItem(plan);
                    },
                  ),
        bottomNavigationBar: SharedBottomNavBar(
          selectedIndex: _bottomNavIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.travelExplorationScreen, (route) => false);
            } else if (index == 1) {
              // Stay on Plan List
            } else if (index == 2) {
              // Guide: Not implemented
            } else if (index == 3) {
              Navigator.pushNamed(context, AppRoutes.profileSettingsScreen);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlanListItem(PlanSummaryModel plan) {
    final itinerary = plan.rawData['itinerary'] as List?;
    String dateRange = '';
    if (itinerary != null && itinerary.isNotEmpty) {
      final dates = itinerary
          .map((e) => DateTime.tryParse(e['date'] ?? '') ?? DateTime.now())
          .toList();
      dates.sort();
      final start = dates.first;
      final end = dates.last;
      dateRange =
          '${start.year}/${_pad2(start.month)}/${_pad2(start.day)} - ${end.year}/${_pad2(end.month)}/${_pad2(end.day)}';
    }
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.planViewScreen,
              arguments: {
                'plan_uuid': plan.planUuid,
                'plan_data': plan.rawData,
              },
            );
          },
          child: Container(
            height: 215.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.h),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Plan image
                Container(
                  width: 104.h,
                  height: 182.h,
                  margin: EdgeInsets.only(left: 16.h, top: 16.h, bottom: 16.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.h),
                    image: DecorationImage(
                      image: AssetImage('assets/images/img_rectangle_462.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: 16.h, right: 16.h, top: 24.h, bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: TextStyleHelper.instance.title16Medium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          plan.destination,
                          style: TextStyleHelper.instance.body14,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          dateRange,
                          style: TextStyleHelper.instance.body12
                              .copyWith(color: Colors.grey),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ...List.generate(
                                4,
                                (i) => Icon(Icons.star,
                                    color: Colors.amber, size: 18)),
                            // SizedBox(width: 8),
                            // Icon(Icons.favorite,
                            //     color: Colors.redAccent, size: 20),
                          ],
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    Color(0xFF2196F3), // Blue background
                                // Không để icon ảnh, chỉ nền xanh
                              ),
                              Icon(Icons.favorite,
                                  color: Colors.white, size: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Icon xóa (thùng rác)
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                barrierColor: Colors.black.withOpacity(0.3),
                builder: (ctx) => DeletePlanDialog(
                  onDelete: () => Navigator.pop(ctx, true),
                  onCancel: () => Navigator.pop(ctx, false),
                ),
              );
              if (confirm == true) {
                final success =
                    await TravelConciergeService().deletePlan(plan.planUuid);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete plan successfully!')),
                  );
                  await _fetchPlans();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete plan failed!')),
                  );
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete, color: Colors.red, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  String _pad2(int n) => n < 10 ? '0$n' : '$n';
}

// Dialog xác nhận xóa plan đồng bộ style với ChangePasswordModal
class DeletePlanDialog extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  const DeletePlanDialog(
      {Key? key, required this.onDelete, required this.onCancel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24.h),
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.circular(16.h),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirm Delete',
                  style: TextStyle(
                    fontSize: 20.fSize,
                    fontWeight: FontWeight.w600,
                    color: appTheme.blackCustom,
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: onCancel,
                  child: Icon(Icons.close, size: 24.h, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'Are you sure you want to delete this plan?',
              style: TextStyle(
                fontSize: 16.fSize,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 32.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    textStyle: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 16.h),
                ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.colorFF0373,
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.h, vertical: 12.h),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
