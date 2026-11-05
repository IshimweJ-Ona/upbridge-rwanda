// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/shared/models/models.dart';

/// Demo content for the pilot, matching the Figma prototype (Sat 17 Oct 2026).
/// Swap this file for API calls when the backend is ready.
abstract final class SampleData {
  static const demoPassword = 'Kigali2026';
  static const today = 'SAT 17 OCT';
  static const pathTitle = 'Web Development Foundations';

  // ───────────────────────────── People & accounts ─────────────────────────────

  static const jean = AppUser(
    id: 'jean',
    name: 'Jean Niyonzima',
    phone: '+250 788 123 456',
    role: Role.youth,
    headline: 'Junior frontend developer · learning on the Web Development path',
    location: 'Kigali · Gasabo',
    about:
        'I finished a diploma in IT in 2025 and I’m learning frontend development through UpBridge. I like building simple, fast pages that work well on the phones most people in Rwanda use.',
  );

  static const alice = AppUser(
    id: 'alice',
    name: 'Alice Uwimana',
    phone: '+250 788 555 010',
    role: Role.mentor,
    headline: 'Frontend engineer · 6 years',
    location: 'Kigali',
  );

  static const claudine = AppUser(
    id: 'claudine',
    name: 'Claudine Uwase',
    phone: '+250 788 333 222',
    role: Role.mentor,
    headline: 'Data analyst · 4 years',
    location: 'Kigali',
    isNewMentor: true,
  );

  static const albert = AppUser(
    id: 'albert',
    name: 'Albert Nkusi',
    phone: '+250 788 000 111',
    role: Role.admin,
    headline: 'Pilot coordinator',
    location: 'Kigali',
  );

  /// Keyed by the last nine digits of the phone number.
  static const accounts = <String, AppUser>{
    '788123456': jean,
    '788555010': alice,
    '788333222': claudine,
    '788000111': albert,
  };

  // ───────────────────────────── Learning path ─────────────────────────────

  static const stages = [
    PathStage(1, 'HTML and CSS foundations', 4, 'Structure, style and publish a page that works on any phone.'),
    PathStage(2, 'JavaScript basics', 5, 'Make pages respond to people: events, forms and data.'),
    PathStage(3, 'Publish and present', 2, 'Turn your work into a case study and talk about it with confidence.'),
  ];

  static const _t3Criteria = [
    Criterion('Semantic structure', 'Uses header, main, section and footer; one h1; headings in order.'),
    Criterion('Layout & responsiveness', 'Readable from 360 px phones to laptops; nothing overflows or overlaps.'),
    Criterion('Code readability', 'Consistent indentation, meaningful class names, CSS in its own file.'),
    Criterion('Accessibility basics', 'Alt text on images, visible focus, colour contrast of at least 4.5:1.'),
  ];

  static const _tasks = <LearningTask>[
    LearningTask(
      id: 't1',
      number: 1,
      stage: 1,
      title: 'Structure a web page with semantic HTML',
      summary: 'Mark up a one-page site about yourself so a screen reader can follow it.',
      duration: 'ABOUT 1 H',
      status: TaskStatus.approved,
      statusNote: 'Approved 9 Oct',
      brief:
          'Build a one-page site about yourself using semantic HTML: header, nav, main, section and footer. Don’t style it yet. Focus on structure that a screen reader and a search engine can follow. When you submit it, a mentor reviews it within 48 hours.',
      deliverables: ['One index.html file', 'A link to the file on GitHub'],
      criteria: [
        Criterion('Semantic elements', 'header, nav, main, section and footer used for their purpose.'),
        Criterion('Headings in order', 'One h1, then h2 and h3 without skipping levels.'),
        Criterion('Images described', 'Every image has meaningful alt text.'),
        Criterion('Valid HTML', 'No errors in the W3C Markup Validation Service.'),
      ],
      resources: [
        Resource(title: 'HTML: A good basis for accessibility', source: 'MDN Web Docs', url: 'https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Accessibility/HTML', kind: 'Guide · 25 min'),
        Resource(title: 'Learn HTML by Building a Cat Photo App', source: 'freeCodeCamp', url: 'https://www.freecodecamp.org/learn/2022/responsive-web-design/', kind: 'Course · 1 h'),
        Resource(title: 'Markup Validation Service', source: 'W3C', url: 'https://validator.w3.org/', kind: 'Tool'),
      ],
    ),
    LearningTask(
      id: 't2',
      number: 2,
      stage: 1,
      title: 'Style text and colour with CSS',
      summary: 'Give your page a readable type scale and accessible colours.',
      duration: 'ABOUT 1.5 H',
      status: TaskStatus.approved,
      statusNote: 'Approved 12 Oct',
      brief: 'Add an external stylesheet to your Task 1 page. Choose a readable type scale, a small colour palette with enough contrast, and consistent spacing.',
      deliverables: ['A styles.css file linked from index.html', 'A link to the repository'],
      criteria: [
        Criterion('Readable type', 'Body text at least 16 px with comfortable line height.'),
        Criterion('Colour contrast', 'Text meets WCAG AA contrast (4.5:1).'),
        Criterion('External stylesheet', 'No inline styles; CSS lives in its own file.'),
        Criterion('Consistent spacing', 'Margins and padding follow a simple scale.'),
      ],
      resources: [
        Resource(title: 'CSS styling basics', source: 'MDN Web Docs', url: 'https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Styling_basics', kind: 'Guide · 40 min'),
        Resource(title: 'Learn Typography by Building a Nutrition Label', source: 'freeCodeCamp', url: 'https://www.freecodecamp.org/learn/2022/responsive-web-design/', kind: 'Course · 1 h'),
      ],
    ),
    LearningTask(
      id: 't3',
      number: 3,
      stage: 1,
      title: 'Build your personal homepage',
      summary: 'Turn your Task 1 page into a homepage you could send to an employer.',
      duration: 'ABOUT 3 H',
      status: TaskStatus.changesRequested,
      statusNote: 'Reviewed today · 09:12',
      brief:
          'Turn your semantic HTML from Task 1 into a personal homepage you could send to an employer: who you are, what you’re learning, two or three things you’ve built, and how to reach you. Publish it with GitHub Pages so anyone can open it on their phone.',
      deliverables: [
        'A live link (GitHub Pages)',
        'A link to the GitHub repository',
        'Two or three sentences on what you built or changed',
      ],
      criteria: _t3Criteria,
      resources: [
        Resource(title: 'Document and website structure', source: 'MDN Web Docs', url: 'https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Structuring_content/Structuring_documents', kind: 'Guide · 30 min'),
        Resource(title: 'Learn CSS Flexbox by Building a Photo Gallery', source: 'freeCodeCamp', url: 'https://www.freecodecamp.org/learn/2022/responsive-web-design/', kind: 'Course · 1 h'),
        Resource(title: 'Creating a GitHub Pages site', source: 'GitHub Docs', url: 'https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site', kind: 'Docs · 15 min'),
      ],
    ),
    LearningTask(
      id: 't4',
      number: 4,
      stage: 1,
      title: 'Make it responsive with Flexbox',
      summary: 'Lay out your projects in a grid that adapts from phone to laptop.',
      duration: 'ABOUT 2 H',
      status: TaskStatus.locked,
      statusNote: 'Unlocks when Task 3 is approved',
      brief: 'Use Flexbox to lay out the projects section of your homepage so it shows one column on phones and two or three on wider screens.',
      deliverables: ['Updated live link', 'Screenshots at 360 px and 1280 px'],
      criteria: [
        Criterion('Flexible layout', 'Uses Flexbox with wrapping rather than fixed widths.'),
        Criterion('Breakpoints', 'Layout changes at sensible widths, tested at 360 px.'),
        Criterion('No overflow', 'Nothing scrolls sideways on a phone.'),
      ],
      resources: [
        Resource(title: 'Flexbox', source: 'MDN Web Docs', url: 'https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/CSS_layout/Flexbox', kind: 'Guide · 35 min'),
      ],
    ),
    LearningTask(id: 't5', number: 5, stage: 2, title: 'Add interactivity with JavaScript', summary: 'Respond to clicks and update the page.', duration: 'ABOUT 2 H', status: TaskStatus.locked),
    LearningTask(id: 't6', number: 6, stage: 2, title: 'Validate a contact form', summary: 'Check input before it is sent and explain errors clearly.', duration: 'ABOUT 2 H', status: TaskStatus.locked),
    LearningTask(id: 't7', number: 7, stage: 2, title: 'Fetch data from an API', summary: 'Load and display live data with fetch().', duration: 'ABOUT 2.5 H', status: TaskStatus.locked),
    LearningTask(id: 't8', number: 8, stage: 2, title: 'Build a to-do list that saves', summary: 'Store data in the browser with localStorage.', duration: 'ABOUT 3 H', status: TaskStatus.locked),
    LearningTask(id: 't9', number: 9, stage: 2, title: 'Debug with browser DevTools', summary: 'Find and fix three planted bugs.', duration: 'ABOUT 1.5 H', status: TaskStatus.locked),
    LearningTask(id: 't10', number: 10, stage: 3, title: 'Write a project case study', summary: 'Explain the problem, your approach and the result.', duration: 'ABOUT 2 H', status: TaskStatus.locked),
    LearningTask(id: 't11', number: 11, stage: 3, title: 'Present your work in a mock interview', summary: 'A 20-minute call with your mentor.', duration: 'ABOUT 1 H', status: TaskStatus.locked),
  ];

  static List<LearningTask> jeanTasks() => List.of(_tasks);

  /// A brand-new youth: Task 1 open, everything else locked.
  static List<LearningTask> freshTasks() => [
        for (final t in _tasks)
          t.number == 1
              ? t.copyWith(status: TaskStatus.available, statusNote: 'Start here')
              : t.copyWith(status: TaskStatus.locked, statusNote: t.number == 2 ? 'Unlocks when Task 1 is approved' : 'Locked'),
      ];

  static const otherPaths = [
    OtherPath(title: 'UI/UX Design Foundations', progress: '1 OF 6 TASKS', note: 'Mentor: David M.', icon: Icons.design_services_outlined),
    OtherPath(title: 'Workplace communication', progress: '4 SHORT TASKS', note: 'Emails, meetings and interviews', icon: Icons.forum_outlined),
  ];

  // ───────────────────────────── Reviews ─────────────────────────────

  static const _reviews = <Review>[
    Review(
      id: 'r-t3-1',
      taskId: 't3',
      mentorName: 'Alice Uwimana',
      when: 'SAT 17 OCT · 09:12',
      approved: false,
      summary:
          'Strong start — the structure is clean and the page reads well. One change before it can go in your portfolio: the footer breaks on small screens.',
      results: [
        CriterionResult('Semantic structure', Verdict.met, 'Good use of header, main and section. One h1 and headings in order.'),
        CriterionResult('Layout & responsiveness', Verdict.partly, 'Below 400 px the footer links run off the right edge. Let them wrap: flex-wrap: wrap on the footer list fixes it.'),
        CriterionResult('Code readability', Verdict.met, 'Clear class names and a separate stylesheet. Easy to follow.'),
        CriterionResult('Accessibility basics', Verdict.met, 'Alt text on both images, good contrast and visible focus outlines.'),
      ],
    ),
    Review(
      id: 'r-t2',
      taskId: 't2',
      mentorName: 'Alice Uwimana',
      when: 'MON 12 OCT · 17:30',
      approved: true,
      summary: 'Readable and calm. Your type scale works well on a small phone.',
      results: [
        CriterionResult('Readable type', Verdict.met, '16 px body with 1.5 line height — comfortable.'),
        CriterionResult('Colour contrast', Verdict.met, 'All text passes AA.'),
        CriterionResult('External stylesheet', Verdict.met, 'Clean separation.'),
        CriterionResult('Consistent spacing', Verdict.met, 'Your 8 px scale is used throughout.'),
      ],
    ),
    Review(
      id: 'r-t1',
      taskId: 't1',
      mentorName: 'Alice Uwimana',
      when: 'FRI 9 OCT · 18:05',
      approved: true,
      summary: 'Solid structure. A screen reader can follow every section.',
      results: [
        CriterionResult('Semantic elements', Verdict.met, 'Every landmark is in place.'),
        CriterionResult('Headings in order', Verdict.met, 'One h1, no skipped levels.'),
        CriterionResult('Images described', Verdict.met, 'Alt text is specific, not just “photo”.'),
        CriterionResult('Valid HTML', Verdict.met, 'Zero validator errors.'),
      ],
    ),
  ];

  static List<Review> jeanReviews() => List.of(_reviews);

  static const t3Approval = Review(
    id: 'r-t3-2',
    taskId: 't3',
    mentorName: 'Alice Uwimana',
    when: 'SAT 17 OCT · 16:40',
    approved: true,
    summary: 'The footer now wraps cleanly at 360 px. All four criteria met — this is ready for your portfolio. Nice work, Jean.',
    results: [
      CriterionResult('Semantic structure', Verdict.met, 'Unchanged and still excellent.'),
      CriterionResult('Layout & responsiveness', Verdict.met, 'Footer wraps cleanly at 360 px and nothing overflows. Well fixed.'),
      CriterionResult('Code readability', Verdict.met, 'Your fix is one clear line with a comment explaining why.'),
      CriterionResult('Accessibility basics', Verdict.met, 'Alt text, contrast and focus all good.'),
    ],
  );

  static const liveUrl = 'https://jeanniyonzima.github.io';
  static const repoUrl = 'https://github.com/jeanniyonzima/homepage';
  static const resubmitNote =
      'I added flex-wrap: wrap to the footer list and tested it at 360 px in Chrome DevTools and on my phone. The links now wrap onto two lines instead of running off the screen.';

  // ───────────────────────────── Portfolio ─────────────────────────────

  static const homepageProject = Project(
    id: 'p-homepage',
    title: 'Personal homepage',
    summary: 'A one-page site that introduces me, my projects and how to reach me. Published with GitHub Pages.',
    skills: ['HTML', 'CSS', 'Flexbox', 'GitHub Pages'],
    addedOn: '17 Oct 2026',
    taskId: 't3',
    liveUrl: liveUrl,
    repoUrl: repoUrl,
    approvedBy: 'Alice Uwimana',
    approvedOn: '17 Oct',
    criteria: '4 OF 4 CRITERIA MET',
    whatIDid: [
      'Structured the page with header, main, section and footer',
      'Built the layout mobile-first and tested it at 360 px',
      'Fixed the footer overflow with flex-wrap after mentor feedback',
    ],
    mentorQuote: 'The footer now wraps cleanly at 360 px. All four criteria met — this is ready for your portfolio.',
    icon: Icons.home_work_outlined,
    tone: Tone.accent,
  );

  static const _projects = <Project>[
    Project(
      id: 'p-styles',
      title: 'Type and colour stylesheet',
      summary: 'A readable type scale and an accessible colour palette for my profile page.',
      skills: ['CSS', 'Accessibility'],
      addedOn: '12 Oct 2026',
      taskId: 't2',
      repoUrl: repoUrl,
      approvedBy: 'Alice Uwimana',
      approvedOn: '12 Oct',
      criteria: '4 OF 4 CRITERIA MET',
      whatIDid: ['Set a 16 px base with a 1.25 type scale', 'Checked every colour pair for AA contrast'],
      mentorQuote: 'Readable and calm. Your type scale works well on a small phone.',
      icon: Icons.format_paint_outlined,
      tone: Tone.info,
    ),
    Project(
      id: 'p-semantic',
      title: 'Semantic HTML profile',
      summary: 'My first page, structured so a screen reader can follow every section.',
      skills: ['HTML', 'Accessibility'],
      addedOn: '9 Oct 2026',
      taskId: 't1',
      repoUrl: repoUrl,
      approvedBy: 'Alice Uwimana',
      approvedOn: '9 Oct',
      criteria: '4 OF 4 CRITERIA MET',
      whatIDid: ['Used landmarks for every section', 'Wrote specific alt text for images', 'Passed the W3C validator'],
      mentorQuote: 'Solid structure. A screen reader can follow every section.',
      icon: Icons.code_rounded,
      tone: Tone.success,
    ),
    Project(
      id: 'p-cafe',
      title: 'Menu page for a café in Remera',
      summary: 'A simple menu page I built for a neighbour’s café so customers can see prices on their phones.',
      skills: ['HTML', 'CSS'],
      addedOn: '3 Oct 2026',
      liveUrl: 'https://jeanniyonzima.github.io/cafe-menu',
      whatIDid: ['Wrote the menu in HTML tables', 'Made the prices readable on small screens'],
      icon: Icons.local_cafe_outlined,
      tone: Tone.neutral,
    ),
  ];

  static List<Project> jeanProjects() => List.of(_projects);

  // ───────────────────────────── Mentors & sessions ─────────────────────────────

  static const mentors = <Mentor>[
    Mentor(
      id: 'alice',
      name: 'Alice Uwimana',
      title: 'Frontend engineer',
      employer: 'Payments company, Kigali',
      years: 6,
      city: 'Kigali',
      bio:
          'I build web apps for a payments company in Kigali and have reviewed junior developers’ code for six years. I care about pages that load fast on a 3G phone and code that the next person can read.',
      skills: ['HTML & CSS', 'JavaScript', 'React', 'Accessibility'],
      helpsWith: ['Code reviews', 'Portfolio feedback', 'First-job interviews'],
      reviews: 46,
      replyTime: '1.4 d',
      mentees: 12,
      availability: 'Tue and Thu · 18:00–20:00',
      languages: 'Kinyarwanda, English',
      tone: Tone.accent,
      slots: [
        SessionSlot('TUE 20 OCT', '18:30'),
        SessionSlot('TUE 20 OCT', '19:30'),
        SessionSlot('THU 22 OCT', '18:00'),
        SessionSlot('THU 22 OCT', '19:00'),
      ],
      isYours: true,
    ),
    Mentor(
      id: 'david',
      name: 'David Munyentwari',
      title: 'Product designer',
      employer: 'Hospitality start-up',
      years: 4,
      city: 'Rubavu',
      bio: 'I design booking flows for hotels around Lake Kivu. I help people new to design learn to test with real users before polishing pixels.',
      skills: ['Figma', 'User research', 'Prototyping'],
      helpsWith: ['Design critique', 'Case studies', 'Usability tests'],
      reviews: 21,
      replyTime: '2.0 d',
      mentees: 7,
      availability: 'Mon and Wed · 19:00–21:00',
      languages: 'Kinyarwanda, English, French',
      tone: Tone.info,
      area: 'UI/UX design',
      slots: [SessionSlot('MON 19 OCT', '19:00'), SessionSlot('WED 21 OCT', '20:00')],
    ),
    Mentor(
      id: 'grace',
      name: 'Grace Mukamana',
      title: 'Data analyst',
      employer: 'Health NGO',
      years: 5,
      city: 'Kigali',
      bio: 'I turn programme data into reports that managers actually read. I can help you get confident with spreadsheets, SQL and clear charts.',
      skills: ['Excel', 'SQL', 'Power BI'],
      helpsWith: ['Spreadsheet skills', 'Reporting', 'CV review'],
      reviews: 33,
      replyTime: '1.1 d',
      mentees: 9,
      availability: 'Sat · 10:00–13:00',
      languages: 'Kinyarwanda, English',
      tone: Tone.success,
      area: 'Data analysis',
      slots: [SessionSlot('SAT 24 OCT', '10:00'), SessionSlot('SAT 24 OCT', '11:30')],
    ),
    Mentor(
      id: 'eric',
      name: 'Eric Habimana',
      title: 'Backend developer',
      employer: 'Software agency',
      years: 8,
      city: 'Huye',
      bio: 'I build APIs and teach evening classes for students in Huye. Happy to help with Python, databases and how to explain your code in interviews.',
      skills: ['Python', 'Django', 'PostgreSQL'],
      helpsWith: ['Code reviews', 'Interview practice'],
      reviews: 52,
      replyTime: '1.8 d',
      mentees: 10,
      availability: 'Full until November',
      languages: 'Kinyarwanda, English, Swahili',
      tone: Tone.warning,
      accepting: false,
    ),
  ];

  static const sessions = <Session>[
    Session(
      id: 's-jean-portfolio',
      mentorId: 'alice',
      mentorName: 'Alice Uwimana',
      youthId: 'jean',
      youthName: 'Jean Niyonzima',
      day: 'TUE 20 OCT',
      time: '18:00',
      topic: 'Portfolio review before applying to Irembo',
      state: SessionState.upcoming,
      link: 'https://meet.google.com/',
    ),
    Session(
      id: 's-jean-plan',
      mentorId: 'alice',
      mentorName: 'Alice Uwimana',
      youthId: 'jean',
      youthName: 'Jean Niyonzima',
      day: 'THU 8 OCT',
      time: '18:00',
      topic: 'Planning my first tasks',
      state: SessionState.done,
    ),
    Session(
      id: 's-emile',
      mentorId: 'alice',
      mentorName: 'Alice Uwimana',
      youthId: 'emile',
      youthName: 'Emile Nkurunziza',
      day: 'THU 22 OCT',
      time: '18:00',
      topic: 'Interview practice',
      note: 'I have an interview for a support role next week and want to practise explaining my projects.',
      state: SessionState.requested,
    ),
    Session(
      id: 's-aline',
      mentorId: 'alice',
      mentorName: 'Alice Uwimana',
      youthId: 'aline',
      youthName: 'Aline Uwase',
      day: 'THU 22 OCT',
      time: '19:00',
      topic: 'Review my work',
      state: SessionState.upcoming,
    ),
    Session(id: 's-patrick', mentorId: 'alice', mentorName: 'Alice Uwimana', youthId: 'patrick', youthName: 'Patrick Nshimiyimana', day: 'THU 15 OCT', time: '18:00', topic: 'Career advice', state: SessionState.done),
    Session(id: 's-clarisse', mentorId: 'alice', mentorName: 'Alice Uwimana', youthId: 'clarisse', youthName: 'Clarisse Umutoni', day: 'TUE 13 OCT', time: '19:00', topic: 'Portfolio feedback', state: SessionState.done),
  ];

  static const mentees = <Mentee>[
    Mentee(id: 'jean', name: 'Jean Niyonzima', path: pathTitle, approved: 2, total: 11, lastActive: 'Active today', status: 'Re-check waiting', tone: Tone.warning, district: 'Gasabo'),
    Mentee(id: 'emile', name: 'Emile Nkurunziza', path: pathTitle, approved: 3, total: 11, lastActive: 'Active today', status: 'Task 4 due in 17 h', tone: Tone.danger, district: 'Kicukiro'),
    Mentee(id: 'aline', name: 'Aline Uwase', path: pathTitle, approved: 1, total: 11, lastActive: 'Yesterday', status: 'Task 2 waiting', tone: Tone.info, district: 'Nyarugenge'),
    Mentee(id: 'sandrine', name: 'Sandrine Mutesi', path: pathTitle, approved: 0, total: 11, lastActive: '2 days ago', status: 'Task 1 waiting', tone: Tone.info, district: 'Gasabo'),
    Mentee(id: 'patrick', name: 'Patrick Nshimiyimana', path: pathTitle, approved: 6, total: 11, lastActive: '3 days ago', status: 'On track', tone: Tone.success, district: 'Kicukiro'),
    Mentee(id: 'clarisse', name: 'Clarisse Umutoni', path: pathTitle, approved: 5, total: 11, lastActive: 'Yesterday', status: 'On track', tone: Tone.success, district: 'Musanze'),
    Mentee(id: 'olivier', name: 'Olivier Mugabo', path: pathTitle, approved: 2, total: 11, lastActive: '9 days ago', status: 'Quiet for 9 days', tone: Tone.warning, district: 'Huye'),
    Mentee(id: 'divine', name: 'Divine Ingabire', path: pathTitle, approved: 4, total: 11, lastActive: 'Active today', status: 'On track', tone: Tone.success, district: 'Gasabo'),
    Mentee(id: 'kevin', name: 'Kevin Iradukunda', path: pathTitle, approved: 3, total: 11, lastActive: '4 days ago', status: 'On track', tone: Tone.success, district: 'Rubavu'),
    Mentee(id: 'josiane', name: 'Josiane Mukeshimana', path: pathTitle, approved: 7, total: 11, lastActive: 'Yesterday', status: 'Applying to jobs', tone: Tone.success, district: 'Nyarugenge'),
    Mentee(id: 'fabrice', name: 'Fabrice Ndayisaba', path: pathTitle, approved: 1, total: 11, lastActive: '12 days ago', status: 'Quiet for 12 days', tone: Tone.warning, district: 'Rwamagana'),
    Mentee(id: 'belyse', name: 'Belyse Uwamahoro', path: pathTitle, approved: 2, total: 11, lastActive: '2 days ago', status: 'On track', tone: Tone.success, district: 'Kicukiro'),
  ];

  static const submissions = <Submission>[
    Submission(
      id: 'sub-emile-t4',
      youthId: 'emile',
      youthName: 'Emile Nkurunziza',
      taskId: 't4',
      taskNumber: 4,
      taskTitle: 'Make it responsive with Flexbox',
      path: pathTitle,
      attempt: 1,
      submittedAt: 'THU 15 OCT · 15:20',
      dueLabel: 'Due in 17 h',
      urgent: true,
      liveUrl: 'https://emilenk.github.io',
      repoUrl: 'https://github.com/emilenk/portfolio',
      reflection: 'I changed the projects list to a flex container that wraps. On my phone it shows one card per row.',
    ),
    Submission(
      id: 'sub-jean-t3',
      youthId: 'jean',
      youthName: 'Jean Niyonzima',
      taskId: 't3',
      taskNumber: 3,
      taskTitle: 'Build your personal homepage',
      path: pathTitle,
      attempt: 2,
      submittedAt: 'SAT 17 OCT · 10:05',
      dueLabel: 'Re-check · due in 46 h',
      liveUrl: liveUrl,
      repoUrl: repoUrl,
      reflection: resubmitNote,
      previousNote: 'Your review on 17 Oct: Layout & responsiveness partly met — footer links overflowed below 400 px.',
    ),
    Submission(
      id: 'sub-aline-t2',
      youthId: 'aline',
      youthName: 'Aline Uwase',
      taskId: 't2',
      taskNumber: 2,
      taskTitle: 'Style text and colour with CSS',
      path: pathTitle,
      attempt: 1,
      submittedAt: 'FRI 16 OCT · 08:40',
      dueLabel: 'Due in 1 d 6 h',
      liveUrl: 'https://alineuwase.github.io',
      repoUrl: 'https://github.com/alineuwase/profile',
      reflection: 'I picked two colours from the Rwandan flag and checked the contrast with WebAIM.',
    ),
    Submission(
      id: 'sub-sandrine-t1',
      youthId: 'sandrine',
      youthName: 'Sandrine Mutesi',
      taskId: 't1',
      taskNumber: 1,
      taskTitle: 'Structure a web page with semantic HTML',
      path: pathTitle,
      attempt: 1,
      submittedAt: 'FRI 16 OCT · 21:10',
      dueLabel: 'Due in 1 d 20 h',
      liveUrl: 'https://sandrinem.github.io',
      repoUrl: 'https://github.com/sandrinem/about-me',
      reflection: 'This is my first web page. I used the validator and fixed two errors.',
    ),
  ];

  // ───────────────────────────── Opportunities ─────────────────────────────

  static const opportunities = <Opportunity>[
    Opportunity(
      id: 'irembo',
      title: 'Frontend Developer Intern',
      org: 'Irembo',
      orgTone: Tone.info,
      kind: 'INTERNSHIP',
      length: '3 MONTHS',
      pay: 'RWF 150K / MONTH',
      place: 'Kigali · on-site',
      closes: 'Fri 30 Oct',
      closesNote: '13 DAYS LEFT',
      repliesBy: 'Fri 20 Nov',
      starts: 'Tue 1 Dec 2026',
      about:
          'Join the team that builds IremboGov, the platform Rwandans use for more than 100 government services. You’ll fix interface bugs, build small components and test pages on the phones citizens actually use.',
      aboutOrg: 'Irembo builds and runs IremboGov, Rwanda’s e-government platform, in partnership with the Government of Rwanda.',
      tasks: [
        'Build and fix interface components with HTML, CSS and JavaScript',
        'Test pages on low-cost Android phones and slow connections',
        'Write a short note explaining every change you make',
      ],
      requirements: [
        Requirement('Semantic HTML and responsive CSS', ReqState.met, 'Tasks 1–2 approved by Alice Uwimana'),
        Requirement('A live project you can show', ReqState.met, 'jeanniyonzima.github.io'),
        Requirement('Basic JavaScript', ReqState.partial, 'Stage 2 of your path covers this'),
        Requirement('Available full-time from 1 December', ReqState.unknown, 'Confirm it in your application note'),
      ],
      category: 'Internships',
      posted: 'Posted 12 Oct',
      applicants: 38,
      postedBy: 'Irembo · verified employer',
      matched: true,
    ),
    Opportunity(
      id: 'tour-site',
      title: 'Website for a tour operator',
      org: 'Musanze tour operator',
      orgTone: Tone.success,
      kind: 'GIG',
      length: '2 WEEKS',
      pay: 'RWF 250K FIXED',
      place: 'Musanze · remote',
      closes: 'Sun 25 Oct',
      closesNote: '8 DAYS LEFT',
      repliesBy: 'Wed 28 Oct',
      starts: 'Mon 2 Nov 2026',
      about: 'A small tour operator near Volcanoes National Park needs a three-page site: tours, prices and a WhatsApp contact button. It must load quickly for visitors on mobile data.',
      aboutOrg: 'A family-run company offering guided hikes and cultural tours around Musanze.',
      tasks: ['Build three responsive pages', 'Add a WhatsApp click-to-chat button', 'Publish the site and hand over editing notes'],
      requirements: [
        Requirement('Responsive pages', ReqState.met, 'Personal homepage approved'),
        Requirement('Can publish a site', ReqState.met, 'GitHub Pages project'),
        Requirement('Basic SEO', ReqState.unknown, 'Not covered yet'),
      ],
      category: 'Gigs',
      posted: 'Posted 10 Oct',
      applicants: 11,
      postedBy: 'Listed by UpBridge partner',
    ),
    Opportunity(
      id: 'bk-techouse',
      title: 'Junior UI/UX Designer',
      org: 'BK TecHouse',
      orgTone: Tone.accent,
      kind: 'FULL-TIME',
      length: '',
      pay: 'RWF 600K–800K / MONTH',
      place: 'Kigali · hybrid',
      closes: 'Sat 7 Nov',
      closesNote: '21 DAYS LEFT',
      repliesBy: 'Sat 21 Nov',
      starts: 'January 2027',
      about: 'Design screens and flows for banking and payment products used across Rwanda. You’ll work with developers and test designs with customers.',
      aboutOrg: 'BK TecHouse is the technology company of BK Group, building digital products for banking, insurance and government services.',
      tasks: ['Design mobile screens in Figma', 'Run quick usability tests', 'Hand over specs to developers'],
      requirements: [
        Requirement('A design portfolio', ReqState.partial, '1 of 6 UI/UX tasks approved'),
        Requirement('HTML and CSS awareness', ReqState.met, 'Tasks 1–2 approved'),
        Requirement('Figma', ReqState.unknown, 'Add Figma work to your portfolio'),
      ],
      category: 'Jobs',
      posted: 'Posted 1 Oct',
      applicants: 54,
      postedBy: 'BK TecHouse · verified employer',
    ),
    Opportunity(
      id: 'mtn',
      title: 'Graduate Trainee, IT',
      org: 'MTN Rwanda',
      orgTone: Tone.warning,
      kind: 'TRAINEE',
      length: '12 MONTHS',
      pay: 'PAID',
      place: 'Kigali · on-site',
      closes: 'Sun 15 Nov',
      closesNote: '29 DAYS LEFT',
      repliesBy: 'Thu 10 Dec',
      starts: 'February 2027',
      about: 'A year-long programme rotating through IT support, networks and digital services, with training and a mentor at MTN.',
      aboutOrg: 'MTN Rwanda is one of the country’s largest mobile network and mobile money operators.',
      tasks: ['Rotate across three IT teams', 'Support internal users', 'Complete a final project'],
      requirements: [
        Requirement('Diploma or degree in IT or related field', ReqState.met, 'Stated in your profile'),
        Requirement('Evidence of practical work', ReqState.met, '3 approved tasks'),
        Requirement('Networking basics', ReqState.unknown, 'Not covered yet'),
      ],
      category: 'Trainee',
      posted: 'Posted 5 Oct',
      applicants: 96,
      postedBy: 'MTN Rwanda · verified employer',
    ),
    Opportunity(
      id: 'library',
      title: 'IT Support Intern',
      org: 'Kigali Public Library',
      orgTone: Tone.neutral,
      kind: 'INTERNSHIP',
      length: '6 MONTHS',
      pay: 'RWF 100K / MONTH',
      place: 'Kigali · on-site',
      closes: 'Wed 30 Sep',
      closesNote: 'CLOSED',
      repliesBy: 'Wed 14 Oct',
      starts: 'Mon 2 Nov 2026',
      about: 'Help library members with computers, Wi-Fi and printing, and keep the public computers running.',
      aboutOrg: 'A public library in Kigali offering books, study space and digital skills classes.',
      tasks: ['Support members with computers', 'Maintain public machines'],
      requirements: [Requirement('Networking basics', ReqState.unknown, '')],
      category: 'Internships',
      posted: 'Posted 1 Sep',
      applicants: 23,
      state: ListingState.closed,
      postedBy: 'Kigali Public Library',
    ),
    Opportunity(
      id: 'typing',
      title: 'Online typing job',
      org: 'Remote Earn Agency',
      orgTone: Tone.danger,
      kind: 'GIG',
      length: 'FLEXIBLE',
      pay: 'RWF 20K / DAY',
      place: 'Remote',
      closes: 'Sat 31 Oct',
      closesNote: '14 DAYS LEFT',
      repliesBy: '—',
      starts: 'Immediately',
      about: 'Earn from home typing documents. Registration fee required to receive your first batch of work.',
      aboutOrg: 'No company registration number provided.',
      tasks: ['Type documents'],
      requirements: [],
      category: 'Gigs',
      posted: 'Posted 15 Oct',
      applicants: 5,
      state: ListingState.reported,
      reports: 3,
      reportReason: 'Asks applicants to pay a RWF 15,000 “registration fee” by mobile money before any work is given.',
      postedBy: 'Unverified poster · joined 15 Oct',
    ),
  ];

  static const applications = <Application>[
    Application(
      id: 'app-tour',
      ref: 'UB-2026-04102',
      oppId: 'tour-site',
      youthId: 'jean',
      youthName: 'Jean Niyonzima',
      status: AppStatus.shortlisted,
      sentOn: 'Sent 11 Oct',
      projectIds: ['p-semantic', 'p-styles'],
      note: 'I can start on 2 November and have built responsive pages that work on mobile data.',
      statusNote: 'Phone interview on Wed 21 Oct at 10:00. The operator will call +250 788 123 456.',
      timeline: [
        TimelineEvent('Sent', 'SUN 11 OCT', detail: 'Profile, 2 projects and your note'),
        TimelineEvent('Checked and forwarded', 'MON 12 OCT', detail: 'UpBridge confirmed your evidence'),
        TimelineEvent('Shortlisted', 'THU 15 OCT', detail: 'Interview on Wed 21 Oct at 10:00 by phone', current: true),
        TimelineEvent('Decision', 'BY WED 28 OCT', done: false),
      ],
    ),
    Application(
      id: 'app-bk',
      ref: 'UB-2026-03921',
      oppId: 'bk-techouse',
      youthId: 'jean',
      youthName: 'Jean Niyonzima',
      status: AppStatus.underReview,
      sentOn: 'Sent 2 Oct',
      projectIds: ['p-semantic'],
      note: 'I’m moving from frontend into design and practise Figma every week.',
      statusNote: 'BK TecHouse is reviewing applications. They’ve committed to reply by Sat 21 Nov.',
      timeline: [
        TimelineEvent('Sent', 'FRI 2 OCT', detail: 'Profile, 1 project and your note'),
        TimelineEvent('Checked by UpBridge', 'SAT 3 OCT', detail: 'Your evidence matched 1 of 3 requirements'),
        TimelineEvent('Forwarded to BK TecHouse', 'MON 5 OCT'),
        TimelineEvent('Under review', 'NOW', detail: 'Reply promised by Sat 21 Nov', current: true),
        TimelineEvent('Decision', 'BY SAT 21 NOV', done: false),
      ],
    ),
    Application(
      id: 'app-library',
      ref: 'UB-2026-02275',
      oppId: 'library',
      youthId: 'jean',
      youthName: 'Jean Niyonzima',
      status: AppStatus.notSelected,
      sentOn: 'Sent 14 Sep',
      projectIds: ['p-cafe'],
      note: 'I help my neighbours with their phones and computers every week.',
      statusNote: 'The library chose a candidate with networking experience. Networking basics are covered in the IT Support path.',
      timeline: [
        TimelineEvent('Sent', 'MON 14 SEP'),
        TimelineEvent('Forwarded to Kigali Public Library', 'TUE 15 SEP'),
        TimelineEvent('Not selected', 'WED 14 OCT', detail: 'Feedback shared by the employer'),
      ],
    ),
  ];

  // ───────────────────────────── Notifications ─────────────────────────────

  static const jeanNotifications = <AppNotification>[
    AppNotification(
      id: 'n-feedback',
      title: 'Alice requested 1 change',
      body: '“Build your personal homepage”: 3 of 4 criteria met. Fix the footer on small screens.',
      time: '09:12',
      icon: Icons.rate_review_outlined,
      tone: Tone.warning,
      route: '/task-feedback/t3',
      unread: true,
    ),
    AppNotification(
      id: 'n-match',
      title: 'New match: Frontend Developer Intern',
      body: 'Irembo · 2 of 4 requirements met by your approved work.',
      time: '08:30',
      icon: Icons.auto_awesome_outlined,
      tone: Tone.accent,
      route: '/opportunity/irembo',
      unread: true,
    ),
    AppNotification(
      id: 'n-checkin',
      title: 'Your monthly check-in is open',
      body: '3 questions · about 2 minutes. It helps us improve the pilot.',
      time: '07:00',
      icon: Icons.fact_check_outlined,
      tone: Tone.info,
      route: '/check-in',
    ),
    AppNotification(
      id: 'n-shortlist',
      title: 'You’re shortlisted',
      body: 'Website for a tour operator · phone interview Wed 21 Oct at 10:00.',
      time: 'THU 15 OCT',
      icon: Icons.star_outline_rounded,
      tone: Tone.success,
      route: '/jobs/applications/app-tour',
      today: false,
    ),
    AppNotification(
      id: 'n-session',
      title: 'Session confirmed with Alice',
      body: 'Tue 20 Oct · 18:00 · Google Meet.',
      time: 'WED 14 OCT',
      icon: Icons.event_available_outlined,
      tone: Tone.info,
      route: '/my-mentorship',
      today: false,
    ),
    AppNotification(
      id: 'n-t2',
      title: 'Task 2 approved',
      body: '“Style text and colour with CSS” is now in your portfolio.',
      time: 'MON 12 OCT',
      icon: Icons.check_circle_outline_rounded,
      tone: Tone.success,
      route: '/task-feedback/t2',
      today: false,
    ),
  ];

  static const welcomeNotification = AppNotification(
    id: 'n-welcome',
    title: 'Welcome to UpBridge',
    body: 'Start Task 1. A mentor reviews your work within 48 hours.',
    time: 'NOW',
    icon: Icons.waving_hand_outlined,
    tone: Tone.accent,
    route: '/task/t1',
    unread: true,
  );

  // ───────────────────────────── Admin ─────────────────────────────

  static const pilotDay = 76;
  static const pilotDays = 92;

  static const objectives = <Objective>[
    Objective(label: 'Youth who completed the course', value: 0.43, target: 0.50, valueLabel: '43%', targetLabel: 'TARGET 50%', note: 'Measurement window closed 3 Oct', closed: true),
    Objective(label: 'Youth matched with a mentor', value: 0.31, target: 0.40, valueLabel: '31%', targetLabel: 'TARGET 40%', note: '128 of 412 youth'),
    Objective(label: 'Portfolios with approved work', value: 0.64, target: 1.0, valueLabel: '64', targetLabel: 'TARGET 100', note: '+9 this week'),
    Objective(label: 'Documented job connections', value: 0.40, target: 1.0, valueLabel: '12', targetLabel: 'TARGET 30', note: 'Interviews, offers and paid gigs'),
    Objective(label: 'Youth surveyed on outcomes', value: 0.22, target: 0.50, valueLabel: '22%', targetLabel: 'TARGET 50%', note: 'Monthly check-in responses'),
  ];

  static const applicants = <MentorApplicant>[
    MentorApplicant(
      id: 'sylvestre',
      name: 'Sylvestre Nsanzimana',
      title: 'Senior software engineer',
      employer: 'Telecom company, Kigali',
      city: 'Kigali',
      years: 9,
      appliedOn: 'Applied 12 Oct',
      skills: ['JavaScript', 'Node.js', 'System design'],
      motivation: 'I was self-taught and someone reviewed my first projects for free. I want to do the same for young developers outside Kigali.',
      availability: 'Wed and Sat · 2 h a week',
      phone: '+250 788 414 702',
      checks: [
        Check('National ID verified', true, 'Name matches ID · checked 13 Oct'),
        Check('Work history confirmed', true, 'Employer letter on file'),
        Check('Reference', true, 'Former manager confirmed by phone, 14 Oct'),
        Check('Code of conduct signed', true, 'Signed 12 Oct'),
      ],
    ),
    MentorApplicant(
      id: 'jeanne',
      name: 'Jeanne Uwera',
      title: 'UX researcher',
      employer: 'University of Rwanda, Huye',
      city: 'Huye',
      years: 5,
      appliedOn: 'Applied 15 Oct',
      skills: ['User research', 'Survey design', 'Figma'],
      motivation: 'I teach research methods and want students to see how design work is judged by employers.',
      availability: 'Tue · 2 h a week',
      phone: '+250 785 300 917',
      checks: [
        Check('National ID verified', true, 'Checked 15 Oct'),
        Check('Work history confirmed', true, 'University staff page'),
        Check('Reference', false, 'Waiting for a reply from the reference'),
        Check('Code of conduct signed', true, 'Signed 15 Oct'),
      ],
    ),
  ];

  static const platformUsers = <PlatformUser>[
    PlatformUser(id: 'u-jean', name: 'Jean Niyonzima', role: Role.youth, phone: '+250 788 123 456', district: 'Gasabo', joined: 'Joined 1 Sep', detail: '2 of 11 tasks · 3 applications'),
    PlatformUser(id: 'u-josiane', name: 'Josiane Mukeshimana', role: Role.youth, phone: '+250 788 412 908', district: 'Nyarugenge', joined: 'Joined 4 Aug', detail: '7 of 11 tasks · 4 applications'),
    PlatformUser(id: 'u-patrick', name: 'Patrick Nshimiyimana', role: Role.youth, phone: '+250 783 220 145', district: 'Kicukiro', joined: 'Joined 6 Aug', detail: '6 of 11 tasks · 2 applications'),
    PlatformUser(id: 'u-clarisse', name: 'Clarisse Umutoni', role: Role.youth, phone: '+250 785 664 310', district: 'Musanze', joined: 'Joined 18 Aug', detail: '5 of 11 tasks · 1 application'),
    PlatformUser(id: 'u-fabrice', name: 'Fabrice Ndayisaba', role: Role.youth, phone: '+250 787 019 552', district: 'Rwamagana', joined: 'Joined 2 Sep', detail: 'Quiet for 12 days', status: 'Inactive'),
    PlatformUser(id: 'u-alice', name: 'Alice Uwimana', role: Role.mentor, phone: '+250 788 555 010', district: 'Kigali', joined: 'Verified 28 Jul', detail: '12 mentees · 46 reviews'),
    PlatformUser(id: 'u-david', name: 'David Munyentwari', role: Role.mentor, phone: '+250 788 671 204', district: 'Rubavu', joined: 'Verified 2 Aug', detail: '7 mentees · 21 reviews'),
    PlatformUser(id: 'u-grace', name: 'Grace Mukamana', role: Role.mentor, phone: '+250 788 903 118', district: 'Kigali', joined: 'Verified 30 Jul', detail: '9 mentees · 33 reviews'),
    PlatformUser(id: 'u-claudine', name: 'Claudine Uwase', role: Role.mentor, phone: '+250 788 333 222', district: 'Kigali', joined: 'Verified 16 Oct', detail: 'New · no mentees yet'),
    PlatformUser(id: 'u-albert', name: 'Albert Nkusi', role: Role.admin, phone: '+250 788 000 111', district: 'Kigali', joined: 'Admin since 20 Jul', detail: 'Pilot coordinator'),
  ];

  static const forwards = <ForwardItem>[
    ForwardItem(
      id: 'f-jean',
      youthName: 'Jean Niyonzima',
      oppId: 'irembo',
      sentOn: 'Sent today · 11:20',
      evidence: '3 approved tasks · personal homepage live',
      applicationId: 'app-irembo',
      checks: [
        Check('Evidence approved by a mentor', true, 'Tasks 1–3 approved by Alice Uwimana'),
        Check('Meets the listing requirements', true, '3 of 4 met; JavaScript in progress'),
        Check('Contact details confirmed', true, '+250 788 123 456'),
        Check('Note answers the employer’s question', true, 'Available full-time from 1 Dec'),
      ],
    ),
    ForwardItem(
      id: 'f-patrick',
      youthName: 'Patrick Nshimiyimana',
      oppId: 'mtn',
      sentOn: 'Sent yesterday',
      evidence: '6 approved tasks · 2 projects',
      checks: [
        Check('Evidence approved by a mentor', true, '6 tasks approved'),
        Check('Meets the listing requirements', true, '2 of 3 met'),
        Check('Contact details confirmed', true, '+250 783 220 145'),
        Check('Note answers the employer’s question', true, 'Diploma from IPRC Kigali'),
      ],
    ),
    ForwardItem(
      id: 'f-clarisse',
      youthName: 'Clarisse Umutoni',
      oppId: 'tour-site',
      sentOn: 'Sent 15 Oct',
      evidence: '5 approved tasks · lives in Musanze',
      checks: [
        Check('Evidence approved by a mentor', true, '5 tasks approved'),
        Check('Meets the listing requirements', true, '3 of 3 met'),
        Check('Contact details confirmed', false, 'Phone number not confirmed yet'),
        Check('Note answers the employer’s question', true, 'Can meet the client in person'),
      ],
    ),
  ];

  static const settings = <String, bool>{
    'replyBy': true,
    'pauseSignups': false,
    'weeklyReport': true,
  };

  // ───────────────────────────── Onboarding ─────────────────────────────

  static const goals = [
    ('job', 'Get my first job or internship', 'Build proof employers trust, then apply', Icons.work_outline_rounded),
    ('gigs', 'Earn from freelance gigs', 'Short paid projects for local businesses', Icons.payments_outlined),
    ('skills', 'Learn a practical skill', 'Follow a path with mentor feedback', Icons.school_outlined),
    ('switch', 'Change career direction', 'Try a new field with real tasks', Icons.alt_route_rounded),
  ];

  static const interestAreas = [
    ('Web development', Icons.code_rounded),
    ('UI/UX design', Icons.design_services_outlined),
    ('Data analysis', Icons.bar_chart_rounded),
    ('Digital marketing', Icons.campaign_outlined),
    ('Mobile apps', Icons.phone_android_rounded),
    ('Office & admin tools', Icons.table_chart_outlined),
    ('Customer support', Icons.support_agent_rounded),
    ('Graphic design', Icons.brush_outlined),
    ('Bookkeeping', Icons.receipt_long_outlined),
  ];
}
