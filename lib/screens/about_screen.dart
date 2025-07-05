import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roms_downloader/widgets/about/info_card.dart';
import 'package:roms_downloader/widgets/about/expandable_info_card.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _packageInfo = info);
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: TextStyle(fontSize: 16)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 40,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset('assets/icon.png', fit: BoxFit.contain),
            ),
            SizedBox(height: 32),
            Text(
              _packageInfo?.appName ?? '-',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _packageInfo?.packageName ?? '-',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version ${_packageInfo?.version ?? '-'}',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 4),
            Text(
              'Build ${_packageInfo?.buildNumber ?? '-'}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 32),
            InfoCard(
              icon: Icons.code_rounded,
              title: 'Source Code',
              subtitle: 'rafaismyname/roms_downloader',
              onTap: () => _copyToClipboard(context, 'https://github.com/rafaismyname/roms_downloader'),
            ),
            SizedBox(height: 16),
            InfoCard(
              icon: Icons.person_rounded,
              title: 'Author',
              subtitle: 'rafaismyname',
              onTap: () => _copyToClipboard(context, 'https://github.com/rafaismyname'),
            ),
            SizedBox(height: 16),
            ExpandableInfoCard(
              icon: Icons.flutter_dash_rounded,
              title: 'Built with',
              items: [
                InfoItem('flutter', 'flutter.dev', 'https://flutter.dev'),
                InfoItem('file_picker', 'pub.dev/packages/file_picker', 'https://pub.dev/packages/file_picker'),
                InfoItem('background_downloader', 'pub.dev/packages/background_downloader', 'https://pub.dev/packages/background_downloader'),
                InfoItem('flutter_riverpod', 'pub.dev/packages/flutter_riverpod', 'https://pub.dev/packages/flutter_riverpod'),
                InfoItem('permission_handler', 'pub.dev/packages/permission_handler', 'https://pub.dev/packages/permission_handler'),
                InfoItem('archive', 'pub.dev/packages/archive', 'https://pub.dev/packages/archive'),
                InfoItem('flutter_archive', 'pub.dev/packages/flutter_archive', 'https://pub.dev/packages/flutter_archive'),
                InfoItem('flutter_foreground_task', 'pub.dev/packages/flutter_foreground_task', 'https://pub.dev/packages/flutter_foreground_task'),
                InfoItem('package_info_plus', 'pub.dev/packages/package_info_plus', 'https://pub.dev/packages/package_info_plus'),
              ],
              onItemTap: (url) => _copyToClipboard(context, url),
            ),
            SizedBox(height: 16),
            ExpandableInfoCard(
              icon: Icons.favorite_rounded,
              initExpanded: true,
              title: 'Special Thanks',
              items: [
                InfoItem('Myrient', 'ROM Archive - myrient.erista.me', 'https://myrient.erista.me'),
              ],
              onItemTap: (url) => _copyToClipboard(context, url),
            ),
            SizedBox(height: 40),
            Text(
              'Made with ❤️ in NYC 🗽',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
