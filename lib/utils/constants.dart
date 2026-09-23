/// Konstanta nama collection Firestore dan nilai tetap lainnya.
class Col {
  static const users = 'users';
  static const alumniProfiles = 'alumni_profiles';
  static const bkkProfiles = 'bkk_profiles';
  static const jobs = 'jobs';
  static const applications = 'applications';
  static const scholarships = 'scholarships';
  static const trainings = 'trainings';
  static const announcements = 'announcements';
  static const banners = 'banners';
  static const bookmarks = 'bookmarks';
  static const notifications = 'notifications';
  static const marketplaceProducts = 'marketplace_products';
}

class Roles {
  static const admin = 'admin';
  static const bkk = 'bkk';
  static const alumni = 'alumni';
}

class AppStatus {
  // Status lamaran
  static const menunggu = 'menunggu';
  static const diproses = 'diproses';
  static const diterima = 'diterima';
  static const ditolak = 'ditolak';

  static const all = [menunggu, diproses, diterima, ditolak];

  // Status lowongan
  static const jobOpen = 'open';
  static const jobClosed = 'closed';
}

class ContentType {
  static const job = 'job';
  static const scholarship = 'scholarship';
  static const training = 'training';
  static const announcement = 'announcement';
}
