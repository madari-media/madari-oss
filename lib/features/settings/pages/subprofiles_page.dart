import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../service/account_profile_service.dart';
import '../service/selected_profile.dart';
import '../widget/profile_dialog.dart';

class SubprofilesPage extends StatefulWidget {
  const SubprofilesPage({super.key});

  @override
  State<SubprofilesPage> createState() => _SubprofilesPageState();
}

class _SubprofilesPageState extends State<SubprofilesPage> {
  final _logger = Logger('SubprofilesPage');
  final _profileService = AccountProfileService.instance;
  final _selectedProfileService = SelectedProfileService.instance;
  List<RecordModel> _profiles = [];
  bool _isLoading = true;
  String? _error;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 3;

  late final StreamSubscription<String?> _selectedProfileSubscription;

  @override
  void initState() {
    super.initState();
    _selectedProfileSubscription = _selectedProfileService.selectedProfileStream
        .listen((_) => setState(() {}));
    _loadProfiles();
  }

  @override
  void dispose() {
    _selectedProfileSubscription.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfiles({bool isRetry = false}) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profiles = await _profileService.getProfiles();

      _selectedProfileService.setSelectedProfile(
        _selectedProfileService.selectedProfileId,
      );

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _isLoading = false;
        _retryAttempts = 0;
      });
    } catch (e, stackTrace) {
      _logger.severe('Error loading profiles', e, stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Failed to load profiles: ${e.toString()}';
      });

      if (isRetry && _retryAttempts < _maxRetryAttempts) {
        _retryAttempts++;
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final backoffDuration = Duration(seconds: pow(2, _retryAttempts).toInt());
    _retryTimer = Timer(backoffDuration, () => _loadProfiles(isRetry: true));
  }

  Future<void> _handleProfileAction(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      await _loadProfiles();
    } catch (e, stackTrace) {
      _logger.severe('Error performing profile action', e, stackTrace);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: ${e.toString()}'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _handleProfileAction(action),
          ),
        ),
      );
    }
  }

  Future<void> _handleProfileSelection(RecordModel profile) async {
    try {
      final currentSelectedId = _selectedProfileService.selectedProfileId;
      final newSelectedId =
          currentSelectedId == profile.id ? profile.id : profile.id;
      await _selectedProfileService.setSelectedProfile(newSelectedId);

      if (!mounted) return;
    } catch (e, stackTrace) {
      _logger.severe('Error selecting profile', e, stackTrace);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select profile: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Profiles', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add new profile',
            onPressed: () => _showProfileDialog(context),
            focusNode: FocusNode(skipTraversal: false),
          ),
        ],
      ),
      body: FocusTraversalGroup(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorRetryWidget(
        error: _error!,
        onRetry: () => _loadProfiles(isRetry: true),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Text(
          'No profiles found. Create one to get started.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProfileCard(_profiles[index]),
              childCount: _profiles.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(RecordModel profile) {
    return ProfileCard(
      profile: profile,
      selectedProfileId: _selectedProfileService.selectedProfileId,
      onTap: () => _handleProfileSelection(profile),
      onEdit: () => _showProfileDialog(context, profile: profile),
      onDelete: () => _showDeleteDialog(profile),
    );
  }

  Future<void> _showProfileDialog(BuildContext context,
      {RecordModel? profile}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ProfileDialog(profile: profile),
    );

    if (result == true) {
      _loadProfiles();
    }
  }

  Future<void> _showDeleteDialog(RecordModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
            'Are you sure you want to delete ${profile.getStringValue('name')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleProfileAction(
          () => _profileService.deleteProfile(profile.id));
    }
  }
}

class ErrorRetryWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorRetryWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final RecordModel profile;
  final String? selectedProfileId;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    this.selectedProfileId,
    this.size = 150,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  bool get isSelected => profile.id == selectedProfileId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FocusTraversalGroup(
      child: SizedBox(
        width: size,
        height: size * 1.2,
        child: Material(
          elevation: isSelected ? 8 : 2,
          shadowColor: colorScheme.shadow.withAlpha(77),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          color:
              isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProfileImage(colorScheme),
                  const SizedBox(height: 12),
                  _buildNameText(theme),
                  const Spacer(),
                  _buildActionButtons(context, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface.withAlpha(230),
              foregroundColor: colorScheme.onSurface,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        if (onDelete != null) const SizedBox(width: 8),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outlined, size: 20),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface.withAlpha(230),
              foregroundColor: colorScheme.error,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImage(ColorScheme colorScheme) {
    final imageSize = size * 0.5;

    return SizedBox(
      width: imageSize,
      height: imageSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withAlpha(51),
                width: 2,
              ),
              image: _getProfileImage(),
            ),
            child: _buildPlaceholderIcon(colorScheme),
          ),
          if (isSelected)
            Positioned(
              right: -4,
              bottom: -4,
              child: _buildSelectedIndicator(colorScheme),
            ),
        ],
      ),
    );
  }

  DecorationImage? _getProfileImage() {
    final imageUrl = profile.getStringValue('profile_image');
    if (imageUrl.isEmpty) return null;

    return DecorationImage(
      image: NetworkImage(
        AppPocketBaseService.instance.pb.files
            .getUrl(profile, imageUrl)
            .toString(),
      ),
      fit: BoxFit.cover,
    );
  }

  Widget? _buildPlaceholderIcon(ColorScheme colorScheme) {
    if (profile.getStringValue('profile_image').isNotEmpty) return null;

    return Center(
      child: Icon(
        Icons.person,
        size: size * 0.25,
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }

  Widget _buildSelectedIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.surface,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check,
        size: 16,
        color: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildNameText(ThemeData theme) {
    return Text(
      profile.getStringValue('name'),
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      maxLines: 2,
    );
  }
}
