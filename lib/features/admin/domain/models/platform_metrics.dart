class PlatformMetrics {
  const PlatformMetrics({
    required this.totalUsers,
    required this.studentCount,
    required this.mentorCount,
    required this.pendingMentorApplications,
    required this.activeMentorships,
    required this.publishedCourses,
    required this.publishedOpportunities,
  });

  final int totalUsers;
  final int studentCount;
  final int mentorCount;
  final int pendingMentorApplications;
  final int activeMentorships;
  final int publishedCourses;
  final int publishedOpportunities;
}
