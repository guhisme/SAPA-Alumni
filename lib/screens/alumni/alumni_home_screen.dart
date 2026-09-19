import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/announcement_model.dart';
import '../../models/application_model.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/application_service.dart';
import '../../services/info_service.dart';
import '../../services/job_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/info_card.dart';
import '../../widgets/job_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_header.dart';
import 'alumni_announcement_detail_screen.dart';
import 'alumni_job_detail_screen.dart';
import 'alumni_main_screen.dart';
import 'alumni_notifications_screen.dart';
import 'alumni_banner_info_screen.dart';

class AlumniHomeScreen extends StatefulWidget {
  const AlumniHomeScreen({super.key});

  @override
  State<AlumniHomeScreen> createState() => _AlumniHomeScreenState();
}

class _AlumniHomeScreenState extends State<AlumniHomeScreen> {
  late final Stream<List<JobModel>> _jobsStream =
      JobService.instance.watchLatestJobs(limit: 4);
  late final Stream<List<AnnouncementModel>> _announcementsStream =
      InfoService.instance.watchAnnouncements(limit: 3);

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              Future.delayed(const Duration(milliseconds: 600)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Header(uid: uid),
              const SizedBox(height: 14),
              const _BannerCarousel(),
              const SizedBox(height: 18),
              _ApplicationSummary(uid: uid),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Lowongan terbaru',
                actionLabel: 'Lihat semua',
                onAction: () => goToAlumniTab(context, 1),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<JobModel>>(
                stream: _jobsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: LoadingView(),
                    );
                  }
                  if (snap.hasError) {
                    return const _MiniMessage(
                      'Gagal memuat lowongan. Periksa koneksi Anda.',
                    );
                  }
                  final jobs = snap.data ?? [];
                  if (jobs.isEmpty) {
                    return const _MiniMessage(
                        'Belum ada lowongan yang dibuka.');
                  }
                  return Column(
                    children: jobs
                        .map((job) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: JobCard(
                                job: job,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AlumniJobDetailScreen(jobId: job.id),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: 'Pengumuman terbaru',
                actionLabel: 'Lihat semua',
                onAction: () => goToAlumniTab(context, 2),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<AnnouncementModel>>(
                stream: _announcementsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: LoadingView(),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const _MiniMessage('Belum ada pengumuman.');
                  }
                  return Column(
                    children: items
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InfoCard(
                                icon: Icons.campaign_rounded,
                                iconColor: AppColors.warning,
                                title: a.title,
                                subtitle: a.content,
                                trailingText: Fmt.relative(a.createdAt),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AlumniAnnouncementDetailScreen(
                                            id: a.id),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _controller = PageController();
  int _current = 0;
  Timer? _autoSlide;

  @override
  void initState() {
    super.initState();
    _autoSlide = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_current + 1) % 2;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlide?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = <_HomeBanner>[
      _HomeBanner(
        title: 'Global Korea Scholarship (GKS)',
        provider: 'National Institute for International Education (NIIED), Republic of Korea',
        description: 'Program beasiswa pemerintah Korea Selatan untuk mahasiswa internasional yang ingin melanjutkan pendidikan tinggi di Korea Selatan. GKS tersedia untuk beberapa jenjang pendidikan melalui jalur pendaftaran yang ditentukan setiap tahun.',
        requirements: 'Memenuhi persyaratan kewarganegaraan, usia, akademik, kesehatan, dan dokumen sesuai panduan GKS tahun berjalan. Persyaratan dapat berbeda berdasarkan jenjang dan jalur pendaftaran.',
        benefits: 'Mendapatkan dukungan biaya pendidikan dan berbagai tunjangan sesuai ketentuan GKS, termasuk biaya perjalanan, biaya pendidikan, tunjangan bulanan, dan dukungan lainnya selama masa studi.',
        assetPath: 'assets/images/scholarship.jpg',
        color: AppColors.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AlumniBannerInfoScreen(
              title: 'Global Korea Scholarship (GKS)',
              provider: 'National Institute for International Education (NIIED), Republic of Korea',
              description: 'Program beasiswa pemerintah Korea Selatan untuk mahasiswa internasional yang ingin melanjutkan pendidikan tinggi di Korea Selatan. GKS tersedia untuk beberapa jenjang pendidikan melalui jalur pendaftaran yang ditentukan setiap tahun.',
              requirements: 'Memenuhi persyaratan kewarganegaraan, usia, akademik, kesehatan, dan dokumen sesuai panduan GKS tahun berjalan. Persyaratan dapat berbeda berdasarkan jenjang dan jalur pendaftaran.',
              benefits: 'Mendapatkan dukungan biaya pendidikan dan berbagai tunjangan sesuai ketentuan GKS, termasuk biaya perjalanan, biaya pendidikan, tunjangan bulanan, dan dukungan lainnya selama masa studi.',
              assetPath: 'assets/images/scholarship.jpg',
              link: 'https://www.kecid.org/news/announcement_detail/81',
            ),
          ),
        ),
      ),
      _HomeBanner(
        title: 'Google Internship',
        provider: 'Google',
        description: 'Program magang yang memberikan kesempatan kepada mahasiswa dan calon profesional untuk memperoleh pengalaman kerja langsung di lingkungan Google. Peserta dapat terlibat dalam proyek nyata, bekerja bersama tim profesional, serta mengembangkan keterampilan teknis dan profesional sesuai bidang yang dipilih.',
        assetPath: 'assets/images/job.jpg',
        color: AppColors.primaryDark,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AlumniBannerInfoScreen(
              title: 'Google Internship',
              provider: 'Google',
              description: 'Program magang yang memberikan kesempatan kepada mahasiswa dan calon profesional untuk memperoleh pengalaman kerja langsung di lingkungan Google. Peserta dapat terlibat dalam proyek nyata, bekerja bersama tim profesional, serta mengembangkan keterampilan teknis dan profesional sesuai bidang yang dipilih.',
              assetPath: 'assets/images/job.jpg',
            ),
          ),
        ),
      ),
    ];
    if (_current >= banners.length) _current = 0;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder: (context, index) => _BannerCard(
              banner: banners[index],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _current == index ? 18 : 6,
              decoration: BoxDecoration(
                color: _current == index ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeBanner {
  final String title;
  final String provider;
  final String description;
  final String requirements;
  final String benefits;
  final String assetPath;
  final Color color;
  final VoidCallback onTap;

  const _HomeBanner({
    required this.title,
    required this.provider,
    required this.description,
    this.requirements = '',
    this.benefits = '',
    required this.assetPath,
    required this.color,
    required this.onTap,
  });
}

class _BannerCard extends StatelessWidget {
  final _HomeBanner banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: GestureDetector(
        onTap: banner.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                banner.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(color: banner.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String uid;
  const _Header({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserService.instance.watchUser(uid),
      builder: (context, snap) {
        final name = snap.data?.name ?? '';
        return Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isEmpty ? '?' : Fmt.initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat datang,',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                  ),
                  Text(
                    name.isEmpty ? 'Alumni' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<int>(
              stream: NotificationService.instance.watchUnreadCount(uid),
              builder: (context, snap) {
                final count = snap.data ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AlumniNotificationsScreen(),
                        ),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Ringkasan jumlah lamaran per status.
class _ApplicationSummary extends StatelessWidget {
  final String uid;
  const _ApplicationSummary({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ApplicationModel>>(
      stream: ApplicationService.instance.watchMyApplications(uid),
      builder: (context, snap) {
        final apps = snap.data ?? [];
        int count(String status) =>
            apps.where((a) => a.status == status).length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ringkasan lamaran',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => goToAlumniTab(context, 3),
                    child: const Text(
                      'Detail',
                      style: TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SummaryItem('Total', apps.length),
                  _SummaryItem('Menunggu', count(AppStatus.menunggu)),
                  _SummaryItem('Diproses', count(AppStatus.diproses)),
                  _SummaryItem('Diterima', count(AppStatus.diterima)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int value;
  const _SummaryItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _MiniMessage extends StatelessWidget {
  final String text;
  const _MiniMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
      ),
    );
  }
}
