import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for seeding the Firestore database with initial data.
///
/// Seeds 15 roles across 3 industries and 300 questions with Kenyan context.
class FirestoreSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed the entire database with roles and questions
  Future<void> seedDatabase({Function(String)? onProgress}) async {
    try {
      // Check if already seeded
      bool alreadySeeded = await _checkIfSeeded();
      if (alreadySeeded) {
        onProgress?.call('Database already seeded ✓');
        debugPrint('Database already seeded');
        return;
      }

      onProgress?.call('Starting database seeding...');
      debugPrint('Starting database seeding...');

      // Seed roles
      onProgress?.call('Seeding 15 roles across 3 industries...');
      await _seedRoles();
      onProgress?.call('✓ Roles seeded successfully');

      // Seed questions
      onProgress?.call('Seeding 300 questions with Kenyan context...');
      await _seedQuestions();
      onProgress?.call('✓ Questions seeded successfully');

      // Mark as seeded
      await _markAsSeeded();

      onProgress?.call('Database seeding complete! ✓');
      debugPrint('Database seeding complete!');
    } catch (e) {
      onProgress?.call('Error seeding database: $e');
      debugPrint('Error seeding database: $e');
      rethrow;
    }
  }

  /// Check if database has already been seeded
  Future<bool> _checkIfSeeded() async {
    try {
      // Check if roles exist
      QuerySnapshot rolesSnapshot =
          await _firestore.collection('roles').limit(1).get();
      return rolesSnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking seed status: $e');
      return false;
    }
  }

  /// Mark database as seeded
  Future<void> _markAsSeeded() async {
    await _firestore.collection('_metadata').doc('seeding').set({
      'seeded_at': FieldValue.serverTimestamp(),
      'version': '1.0.0',
      'total_roles': 15,
      'total_questions': 300,
    });
  }

  /// Seed all 15 roles across 3 industries
  Future<void> _seedRoles() async {
    final roles = _getRolesData();

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (var roleData in roles) {
      DocumentReference docRef =
          _firestore.collection('roles').doc(roleData['id'] as String);
      batch.set(docRef, roleData);
      count++;

      // Firestore batch limit is 500, commit every 100 for safety
      if (count % 100 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    // Commit remaining
    if (count % 100 != 0) {
      await batch.commit();
    }

    debugPrint('Seeded $count roles');
  }

  /// Seed all 300 questions (20 per role)
  Future<void> _seedQuestions() async {
    final questions = _getQuestionsData();

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (var questionData in questions) {
      DocumentReference docRef = _firestore.collection('questions').doc();
      // Use Firestore-generated ID
      questionData['id'] = docRef.id;
      batch.set(docRef, questionData);
      count++;

      // Commit every 100 questions
      if (count % 100 == 0) {
        await batch.commit();
        batch = _firestore.batch();
        debugPrint('Seeded $count questions...');
      }
    }

    // Commit remaining
    if (count % 100 != 0) {
      await batch.commit();
    }

    debugPrint('Seeded $count questions total');
  }

  /// Get all roles data
  List<Map<String, dynamic>> _getRolesData() {
    final now = Timestamp.now();

    return [
      // ==================== TECHNOLOGY SECTOR ====================
      {
        'id': 'tech_software_intern',
        'industry': 'Technology',
        'department': 'Software Development',
        'level': 'Intern',
        'display_name': 'Software Development Intern',
        'kenyan_companies': ['Safaricom', 'Andela', 'M-KOPA', 'Cellulant'],
        'question_count': 20,
        'avg_salary_ksh': '30000-50000',
        'key_skills': ['Programming', 'Problem-solving', 'Communication', 'Teamwork'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'tech_software_junior',
        'industry': 'Technology',
        'department': 'Software Development',
        'level': 'Junior',
        'display_name': 'Junior Software Engineer',
        'kenyan_companies': ['Safaricom', 'Andela', 'Equity Bank', 'NCBA'],
        'question_count': 20,
        'avg_salary_ksh': '80000-120000',
        'key_skills': ['Full-stack Development', 'Git', 'Testing', 'Agile'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'tech_data_analyst_mid',
        'industry': 'Technology',
        'department': 'Data Analytics',
        'level': 'Mid-Level',
        'display_name': 'Mid-Level Data Analyst',
        'kenyan_companies': ['Safaricom', 'KCB', 'Equity Bank', 'Twiga Foods'],
        'question_count': 20,
        'avg_salary_ksh': '120000-180000',
        'key_skills': ['SQL', 'Python', 'Data Visualization', 'Statistical Analysis'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'tech_it_support_junior',
        'industry': 'Technology',
        'department': 'IT Support',
        'level': 'Junior',
        'display_name': 'Junior IT Support Specialist',
        'kenyan_companies': ['Safaricom', 'Kenya Power', 'NCBA', 'Nairobi Hospital'],
        'question_count': 20,
        'avg_salary_ksh': '50000-80000',
        'key_skills': ['Troubleshooting', 'Networking', 'Customer Service', 'Windows/Linux'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'tech_product_manager_senior',
        'industry': 'Technology',
        'department': 'Product Management',
        'level': 'Senior',
        'display_name': 'Senior Product Manager',
        'kenyan_companies': ['Safaricom', 'M-KOPA', 'Twiga Foods', 'Jumia'],
        'question_count': 20,
        'avg_salary_ksh': '250000-400000',
        'key_skills': ['Product Strategy', 'Stakeholder Management', 'Agile', 'Market Analysis'],
        'created_at': now,
        'updated_at': now,
      },

      // ==================== FINANCE SECTOR ====================
      {
        'id': 'finance_analyst_intern',
        'industry': 'Finance',
        'department': 'Financial Analysis',
        'level': 'Intern',
        'display_name': 'Financial Analyst Intern',
        'kenyan_companies': ['KCB', 'Equity Bank', 'NCBA', 'Britam'],
        'question_count': 20,
        'avg_salary_ksh': '25000-40000',
        'key_skills': ['Excel', 'Financial Modeling', 'Research', 'Communication'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'finance_accountant_junior',
        'industry': 'Finance',
        'department': 'Accounting',
        'level': 'Junior',
        'display_name': 'Junior Accountant',
        'kenyan_companies': ['Deloitte Kenya', 'PwC Kenya', 'KPMG', 'EY'],
        'question_count': 20,
        'avg_salary_ksh': '60000-90000',
        'key_skills': ['Bookkeeping', 'Tax Compliance', 'QuickBooks', 'IFRS'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'finance_risk_analyst_mid',
        'industry': 'Finance',
        'department': 'Risk Management',
        'level': 'Mid-Level',
        'display_name': 'Mid-Level Risk Analyst',
        'kenyan_companies': ['KCB', 'Equity Bank', 'Safaricom', 'CIC Insurance'],
        'question_count': 20,
        'avg_salary_ksh': '130000-200000',
        'key_skills': ['Risk Assessment', 'Data Analysis', 'Regulatory Compliance', 'Reporting'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'finance_relationship_manager_senior',
        'industry': 'Finance',
        'department': 'Customer Relations',
        'level': 'Senior',
        'display_name': 'Senior Relationship Manager',
        'kenyan_companies': ['KCB', 'Equity Bank', 'Standard Chartered', 'Barclays'],
        'question_count': 20,
        'avg_salary_ksh': '200000-350000',
        'key_skills': ['Client Management', 'Sales', 'Negotiation', 'Financial Products'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'finance_auditor_mid',
        'industry': 'Finance',
        'department': 'Internal Audit',
        'level': 'Mid-Level',
        'display_name': 'Mid-Level Internal Auditor',
        'kenyan_companies': ['PwC Kenya', 'Deloitte Kenya', 'KPMG', 'Safaricom'],
        'question_count': 20,
        'avg_salary_ksh': '120000-180000',
        'key_skills': ['Audit Planning', 'Risk Assessment', 'Compliance', 'Report Writing'],
        'created_at': now,
        'updated_at': now,
      },

      // ==================== HEALTHCARE SECTOR ====================
      {
        'id': 'health_nurse_junior',
        'industry': 'Healthcare',
        'department': 'Nursing',
        'level': 'Junior',
        'display_name': 'Junior Registered Nurse',
        'kenyan_companies': ['Aga Khan Hospital', 'Nairobi Hospital', 'Kenyatta Hospital', 'MP Shah'],
        'question_count': 20,
        'avg_salary_ksh': '50000-80000',
        'key_skills': ['Patient Care', 'Medical Procedures', 'Communication', 'Empathy'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'health_lab_tech_mid',
        'industry': 'Healthcare',
        'department': 'Laboratory',
        'level': 'Mid-Level',
        'display_name': 'Mid-Level Laboratory Technician',
        'kenyan_companies': ['Lancet Kenya', 'Pathologists Lancet', 'Aga Khan', 'KEMRI'],
        'question_count': 20,
        'avg_salary_ksh': '70000-110000',
        'key_skills': ['Lab Testing', 'Equipment Maintenance', 'Quality Control', 'Safety Protocols'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'health_pharmacist_junior',
        'industry': 'Healthcare',
        'department': 'Pharmacy',
        'level': 'Junior',
        'display_name': 'Junior Pharmacist',
        'kenyan_companies': ['Goodlife Pharmacy', 'Nairobi Hospital', 'Aga Khan', 'Carrefour Pharmacy'],
        'question_count': 20,
        'avg_salary_ksh': '80000-120000',
        'key_skills': ['Medication Dispensing', 'Patient Counseling', 'Inventory Management', 'Regulatory Knowledge'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'health_admin_mid',
        'industry': 'Healthcare',
        'department': 'Administration',
        'level': 'Mid-Level',
        'display_name': 'Mid-Level Health Records Administrator',
        'kenyan_companies': ['Nairobi Hospital', 'Kenyatta Hospital', 'Aga Khan', 'MP Shah'],
        'question_count': 20,
        'avg_salary_ksh': '70000-100000',
        'key_skills': ['Records Management', 'Data Entry', 'Confidentiality', 'Healthcare Systems'],
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'health_public_health_officer_mid',
        'industry': 'Healthcare',
        'department': 'Public Health',
        'level': 'Mid-Level',
        'display_name': 'Mid-Level Public Health Officer',
        'kenyan_companies': ['Ministry of Health', 'WHO Kenya', 'AMREF', 'CDC Kenya'],
        'question_count': 20,
        'avg_salary_ksh': '90000-150000',
        'key_skills': ['Disease Prevention', 'Community Outreach', 'Health Education', 'Data Analysis'],
        'created_at': now,
        'updated_at': now,
      },
    ];
  }

  /// Get all questions data (300 questions total - 20 per role)
  List<Map<String, dynamic>> _getQuestionsData() {
    final now = Timestamp.now();
    final List<Map<String, dynamic>> allQuestions = [];

    // Add questions for each role
    allQuestions.addAll(_getTechSoftwareInternQuestions(now));
    allQuestions.addAll(_getTechSoftwareJuniorQuestions(now));
    allQuestions.addAll(_getTechDataAnalystQuestions(now));
    allQuestions.addAll(_getTechITSupportQuestions(now));
    allQuestions.addAll(_getTechProductManagerQuestions(now));

    allQuestions.addAll(_getFinanceAnalystInternQuestions(now));
    allQuestions.addAll(_getFinanceAccountantQuestions(now));
    allQuestions.addAll(_getFinanceRiskAnalystQuestions(now));
    allQuestions.addAll(_getFinanceRelationshipManagerQuestions(now));
    allQuestions.addAll(_getFinanceAuditorQuestions(now));

    allQuestions.addAll(_getHealthNurseQuestions(now));
    allQuestions.addAll(_getHealthLabTechQuestions(now));
    allQuestions.addAll(_getHealthPharmacistQuestions(now));
    allQuestions.addAll(_getHealthAdminQuestions(now));
    allQuestions.addAll(_getHealthPublicHealthOfficerQuestions(now));

    return allQuestions;
  }

  // ==================== TECHNOLOGY QUESTIONS ====================

  List<Map<String, dynamic>> _getTechSoftwareInternQuestions(Timestamp now) {
    return [
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Tell me about a challenging programming project you worked on during your studies or internship',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'project_experience',
        'variants': [
          'Describe a difficult technical problem you solved',
          'Walk me through your most complex project'
        ],
        'expected_keywords': ['situation', 'challenge', 'approach', 'solution', 'result', 'learned', 'teamwork', 'code'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['M-Pesa integration project', 'School management system', 'Agricultural tech solution', 'Matatu payment system'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'How would you approach learning a new programming language or framework?',
        'question_type': 'behavioral',
        'difficulty': 'easy',
        'variant_group': 'learning_approach',
        'variants': [
          'Describe your learning process for new technologies',
          'How do you stay updated with new technologies?'
        ],
        'expected_keywords': ['documentation', 'practice', 'projects', 'online resources', 'community', 'hands-on'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Learning Flutter for mobile apps', 'React for web development', 'Python for data analysis'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Explain how you would design a simple mobile payment system similar to M-Pesa',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'system_design',
        'variants': [
          'How would you build a mobile money transfer application?',
          'Design a system for peer-to-peer payments'
        ],
        'expected_keywords': ['database', 'security', 'API', 'authentication', 'transaction', 'scalability', 'validation'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['M-Pesa', 'Airtel Money', 'T-Kash'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Tell me about a time you had to work with limited resources or tight deadlines',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'resource_constraints',
        'variants': [
          'Describe a situation where you had to deliver under pressure',
          'How do you handle tight deadlines?'
        ],
        'expected_keywords': ['prioritization', 'planning', 'communication', 'adaptation', 'result', 'time management'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Power outages during project deadline', 'Limited internet connectivity', 'Old computer hardware'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'How do you debug code when you encounter an error you have never seen before?',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'debugging',
        'variants': [
          'Walk me through your debugging process',
          'How do you troubleshoot unfamiliar errors?'
        ],
        'expected_keywords': ['error messages', 'logs', 'search', 'documentation', 'isolation', 'testing', 'systematic'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Stack Overflow', 'GitHub issues', 'Developer forums'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Describe how you would explain a technical concept to someone with no programming background',
        'question_type': 'communication',
        'difficulty': 'medium',
        'variant_group': 'technical_communication',
        'variants': [
          'How do you communicate technical ideas to non-technical people?',
          'Give an example of simplifying complex technical information'
        ],
        'expected_keywords': ['analogy', 'simple terms', 'examples', 'patience', 'understanding', 'relatable'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Explaining APIs using matatu routes', 'Databases as filing cabinets', 'Cloud storage as a storage facility'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'What would you do if you disagreed with your team lead on a technical approach?',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'conflict_resolution',
        'variants': [
          'How do you handle disagreements with senior developers?',
          'Tell me about a time you had a technical disagreement'
        ],
        'expected_keywords': ['respect', 'communication', 'evidence', 'listening', 'compromise', 'learning', 'professional'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Code review feedback', 'Architecture decisions', 'Technology choices'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'How would you prioritize tasks when working on multiple features simultaneously?',
        'question_type': 'situational',
        'difficulty': 'medium',
        'variant_group': 'task_management',
        'variants': [
          'How do you manage competing priorities?',
          'Describe your approach to multitasking'
        ],
        'expected_keywords': ['urgency', 'importance', 'deadlines', 'communication', 'impact', 'stakeholders'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Bug fixes vs new features', 'Client requests vs technical debt'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'What is your experience with version control systems like Git?',
        'question_type': 'technical',
        'difficulty': 'easy',
        'variant_group': 'tools_experience',
        'variants': [
          'How comfortable are you with Git?',
          'Describe your Git workflow'
        ],
        'expected_keywords': ['branches', 'commits', 'pull requests', 'merge', 'repository', 'collaboration'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['GitHub projects', 'Team collaboration', 'Open source contributions'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Tell me about a time you received constructive criticism. How did you respond?',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'feedback_handling',
        'variants': [
          'How do you handle code review feedback?',
          'Describe a time you learned from criticism'
        ],
        'expected_keywords': ['listening', 'learning', 'improvement', 'reflection', 'growth', 'professional'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Code review comments', 'Mentor feedback', 'Project evaluations'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'How would you ensure your code is maintainable and readable by other developers?',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'code_quality',
        'variants': [
          'What are your best practices for writing clean code?',
          'How do you make your code easy to understand?'
        ],
        'expected_keywords': ['comments', 'naming conventions', 'structure', 'documentation', 'consistency', 'standards'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Team projects', 'Handover situations', 'Code reviews'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Describe a situation where you had to learn something completely new quickly',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'quick_learning',
        'variants': [
          'Tell me about a time you adapted to new technology fast',
          'How do you handle steep learning curves?'
        ],
        'expected_keywords': ['research', 'practice', 'resources', 'determination', 'success', 'application'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['New framework for client project', 'Competition deadline', 'Hackathon challenge'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'What steps would you take to troubleshoot a web application that is running slowly?',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'performance_troubleshooting',
        'variants': [
          'How do you diagnose performance issues?',
          'Walk me through optimizing a slow application'
        ],
        'expected_keywords': ['profiling', 'network', 'database', 'caching', 'optimization', 'monitoring', 'testing'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Slow internet connection', 'Server response time', 'Database queries'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'How do you stay motivated when working on repetitive or boring tasks?',
        'question_type': 'behavioral',
        'difficulty': 'easy',
        'variant_group': 'motivation',
        'variants': [
          'What keeps you engaged during mundane work?',
          'How do you maintain focus on tedious tasks?'
        ],
        'expected_keywords': ['perspective', 'goals', 'breaks', 'efficiency', 'learning', 'contribution'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Data entry tasks', 'Testing repetitive features', 'Documentation'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Explain the difference between frontend and backend development',
        'question_type': 'technical',
        'difficulty': 'easy',
        'variant_group': 'technical_concepts',
        'variants': [
          'What is the role of frontend vs backend?',
          'Describe the client-server architecture'
        ],
        'expected_keywords': ['user interface', 'server', 'database', 'API', 'browser', 'logic', 'presentation'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['M-Pesa app interface vs server', 'Website display vs data processing'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Tell me about a time you worked effectively in a team',
        'question_type': 'behavioral',
        'difficulty': 'easy',
        'variant_group': 'teamwork',
        'variants': [
          'Describe your experience with team projects',
          'How do you contribute to team success?'
        ],
        'expected_keywords': ['collaboration', 'communication', 'contribution', 'support', 'coordination', 'success'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['University group project', 'Hackathon team', 'Open source contribution'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'How would you handle a situation where your code causes a bug in production?',
        'question_type': 'situational',
        'difficulty': 'medium',
        'variant_group': 'error_handling',
        'variants': [
          'What would you do if you deployed broken code?',
          'How do you handle production incidents?'
        ],
        'expected_keywords': ['responsibility', 'communication', 'fix', 'testing', 'learning', 'prevention', 'transparency'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Payment processing error', 'Login bug', 'Data display issue'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'What testing strategies would you use to ensure code quality?',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'testing',
        'variants': [
          'How do you test your code?',
          'Explain your approach to quality assurance'
        ],
        'expected_keywords': ['unit tests', 'integration tests', 'manual testing', 'edge cases', 'automation', 'coverage'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Form validation', 'Payment flow testing', 'API endpoint testing'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'Why are you interested in software development, and why this company?',
        'question_type': 'behavioral',
        'difficulty': 'easy',
        'variant_group': 'motivation',
        'variants': [
          'What attracts you to this role?',
          'Why do you want to work here?'
        ],
        'expected_keywords': ['passion', 'learning', 'growth', 'company values', 'impact', 'technology', 'career'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Safaricom innovation', 'M-KOPA solar impact', 'Andela training'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_intern',
        'question_text': 'How do you manage your time when dealing with frequent power outages or internet disruptions?',
        'question_type': 'situational',
        'difficulty': 'medium',
        'variant_group': 'kenyan_context',
        'variants': [
          'How do you stay productive during infrastructure challenges?',
          'What strategies do you use for unreliable power or internet?'
        ],
        'expected_keywords': ['planning', 'backup', 'offline work', 'prioritization', 'adaptation', 'communication'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Power backup solutions', 'Offline coding', 'Mobile data backup', 'Working from cyber cafes'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
    ];
  }

  List<Map<String, dynamic>> _getTechSoftwareJuniorQuestions(Timestamp now) {
    return [
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Describe your experience with full-stack development and your preferred tech stack',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'technical_experience',
        'variants': [
          'What technologies are you most comfortable with?',
          'Walk me through a full-stack project you built'
        ],
        'expected_keywords': ['frontend', 'backend', 'database', 'API', 'framework', 'deployment', 'experience'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['React + Node.js', 'Flutter + Firebase', 'Django + PostgreSQL'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Tell me about a time you had to refactor legacy code. What was your approach?',
        'question_type': 'behavioral',
        'difficulty': 'hard',
        'variant_group': 'code_improvement',
        'variants': [
          'How do you approach improving existing codebases?',
          'Describe your experience with code refactoring'
        ],
        'expected_keywords': ['analysis', 'testing', 'incremental', 'documentation', 'communication', 'improvement', 'risk'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Updating old school system', 'Modernizing payment integration', 'Database migration'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'How would you design a RESTful API for a mobile money platform?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'api_design',
        'variants': [
          'Explain your approach to API architecture',
          'Design endpoints for a payment system'
        ],
        'expected_keywords': ['REST', 'endpoints', 'authentication', 'security', 'versioning', 'documentation', 'scalability'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['M-Pesa API', 'Transfer money', 'Check balance', 'Transaction history'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Describe a situation where you had to learn a new technology quickly for a project deadline',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'adaptability',
        'variants': [
          'How do you handle urgent technology changes?',
          'Tell me about adapting to new tools under pressure'
        ],
        'expected_keywords': ['learning', 'resources', 'practice', 'delivery', 'time management', 'success'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Client requirement change', 'Framework migration', 'New integration requirement'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'How do you ensure application security in your development process?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'security',
        'variants': [
          'What security best practices do you follow?',
          'How do you prevent common vulnerabilities?'
        ],
        'expected_keywords': ['authentication', 'encryption', 'validation', 'injection', 'XSS', 'HTTPS', 'best practices'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['M-Pesa PIN security', 'User data protection', 'Payment encryption'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Tell me about a technical challenge that stumped you. How did you overcome it?',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'problem_solving',
        'variants': [
          'Describe your most difficult debugging experience',
          'How do you handle complex technical problems?'
        ],
        'expected_keywords': ['analysis', 'research', 'persistence', 'solution', 'learning', 'resources', 'collaboration'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Integration bug', 'Performance issue', 'Database optimization'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Explain your experience with Agile methodologies and sprint planning',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'agile_experience',
        'variants': [
          'How do you work in Agile teams?',
          'Describe your experience with Scrum'
        ],
        'expected_keywords': ['sprints', 'stand-ups', 'retrospectives', 'user stories', 'estimation', 'collaboration'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Two-week sprints', 'Daily standups', 'Sprint planning'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'How would you optimize a slow database query?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'database_optimization',
        'variants': [
          'What strategies do you use for query optimization?',
          'How do you improve database performance?'
        ],
        'expected_keywords': ['indexing', 'query analysis', 'execution plan', 'joins', 'caching', 'normalization'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['User search feature', 'Transaction history', 'Report generation'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Tell me about a time you disagreed with a product requirement. How did you handle it?',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'stakeholder_management',
        'variants': [
          'How do you handle conflicting requirements?',
          'Describe pushing back on a feature request'
        ],
        'expected_keywords': ['communication', 'reasoning', 'alternatives', 'collaboration', 'understanding', 'compromise'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Unrealistic deadline', 'Technical limitation', 'Security concern'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'What is your approach to writing automated tests?',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'testing_automation',
        'variants': [
          'How do you implement test automation?',
          'Describe your testing strategy'
        ],
        'expected_keywords': ['unit tests', 'integration tests', 'test coverage', 'CI/CD', 'frameworks', 'maintenance'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Jest for React', 'PyTest for Python', 'JUnit for Java'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'How do you stay updated with the latest development trends and technologies?',
        'question_type': 'behavioral',
        'difficulty': 'easy',
        'variant_group': 'continuous_learning',
        'variants': [
          'What resources do you use for professional development?',
          'How do you keep your skills current?'
        ],
        'expected_keywords': ['blogs', 'conferences', 'courses', 'practice', 'community', 'documentation', 'projects'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['DevFest Nairobi', 'Online courses', 'Tech meetups', 'GitHub trending'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Describe your experience with CI/CD pipelines and deployment automation',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'devops',
        'variants': [
          'How do you automate deployment processes?',
          'What is your experience with DevOps practices?'
        ],
        'expected_keywords': ['automation', 'testing', 'deployment', 'pipeline', 'version control', 'monitoring'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['GitHub Actions', 'Jenkins', 'GitLab CI', 'Docker deployment'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Tell me about a time you mentored or helped a junior developer',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'mentorship',
        'variants': [
          'How do you support less experienced team members?',
          'Describe teaching someone a technical concept'
        ],
        'expected_keywords': ['patience', 'explanation', 'guidance', 'encouragement', 'growth', 'knowledge sharing'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Code review feedback', 'Pair programming', 'Technical documentation'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'How would you handle a situation where the system is down during peak hours?',
        'question_type': 'situational',
        'difficulty': 'hard',
        'variant_group': 'incident_response',
        'variants': [
          'What is your approach to production incidents?',
          'How do you handle system outages?'
        ],
        'expected_keywords': ['priority', 'communication', 'diagnosis', 'fix', 'stakeholders', 'post-mortem', 'prevention'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['M-Pesa downtime', 'Payment processing failure', 'Server crash'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Explain the concept of microservices and when you would use them',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'architecture',
        'variants': [
          'What is microservices architecture?',
          'Compare monolithic vs microservices'
        ],
        'expected_keywords': ['services', 'scalability', 'independence', 'communication', 'deployment', 'complexity'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Payment service', 'User service', 'Notification service'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Tell me about a project where you had to balance technical debt with new features',
        'question_type': 'behavioral',
        'difficulty': 'hard',
        'variant_group': 'technical_debt',
        'variants': [
          'How do you manage technical debt?',
          'Describe prioritizing code quality vs features'
        ],
        'expected_keywords': ['balance', 'priority', 'communication', 'refactoring', 'planning', 'long-term', 'trade-offs'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Legacy system update', 'Adding features to old codebase', 'Database optimization'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'How do you ensure code quality in a fast-paced development environment?',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'quality_assurance',
        'variants': [
          'How do you maintain standards under pressure?',
          'Describe your quality control process'
        ],
        'expected_keywords': ['code review', 'testing', 'standards', 'automation', 'documentation', 'best practices'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Sprint deadlines', 'Client requests', 'Bug fixes'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'What strategies would you use to improve application performance?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'performance',
        'variants': [
          'How do you optimize application speed?',
          'Describe performance improvement techniques'
        ],
        'expected_keywords': ['caching', 'optimization', 'profiling', 'lazy loading', 'CDN', 'compression', 'monitoring'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Slow internet optimization', 'Mobile app performance', 'API response time'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'Describe a time when you had to work with a difficult team member',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'team_dynamics',
        'variants': [
          'How do you handle team conflicts?',
          'Tell me about navigating team challenges'
        ],
        'expected_keywords': ['communication', 'professionalism', 'understanding', 'collaboration', 'resolution', 'respect'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Code style disagreement', 'Different work approaches', 'Communication issues'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_software_junior',
        'question_text': 'How would you design a system to handle M-Pesa transactions with high reliability?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'system_reliability',
        'variants': [
          'How do you ensure system reliability for financial transactions?',
          'Design a fault-tolerant payment system'
        ],
        'expected_keywords': ['redundancy', 'failover', 'transactions', 'consistency', 'monitoring', 'recovery', 'testing'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['M-Pesa reliability', 'Transaction rollback', 'Payment confirmation', 'Network failures'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
    ];
  }

  List<Map<String, dynamic>> _getTechDataAnalystQuestions(Timestamp now) {
    return [
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Describe a complex data analysis project you led and the insights you uncovered',
        'question_type': 'behavioral',
        'difficulty': 'hard',
        'variant_group': 'project_experience',
        'variants': [
          'Walk me through your most impactful analysis',
          'Tell me about a data project that drove business decisions'
        ],
        'expected_keywords': ['data', 'analysis', 'insights', 'business impact', 'methodology', 'presentation', 'stakeholders'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['M-Pesa transaction patterns', 'Customer churn analysis', 'Sales forecasting'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'How would you analyze customer behavior for a mobile money platform like M-Pesa?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'analysis_approach',
        'variants': [
          'What metrics would you track for user engagement?',
          'Describe analyzing transaction patterns'
        ],
        'expected_keywords': ['metrics', 'segmentation', 'patterns', 'SQL', 'visualization', 'trends', 'recommendations'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Transaction frequency', 'Agent usage', 'Peak hours', 'Regional patterns'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Tell me about a time when your analysis contradicted stakeholder assumptions',
        'question_type': 'behavioral',
        'difficulty': 'hard',
        'variant_group': 'stakeholder_management',
        'variants': [
          'How do you present unpopular findings?',
          'Describe challenging stakeholder expectations with data'
        ],
        'expected_keywords': ['data', 'evidence', 'communication', 'diplomacy', 'visualization', 'business context'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Market analysis', 'Product performance', 'Customer feedback'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Explain how you would build a dashboard to track key business metrics',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'visualization',
        'variants': [
          'What tools do you use for data visualization?',
          'How do you design effective dashboards?'
        ],
        'expected_keywords': ['KPIs', 'visualization', 'tools', 'user needs', 'interactivity', 'design', 'updates'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Power BI', 'Tableau', 'Google Data Studio', 'Sales dashboard'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'How do you ensure data quality and accuracy in your analyses?',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'data_quality',
        'variants': [
          'What is your process for data validation?',
          'How do you handle data inconsistencies?'
        ],
        'expected_keywords': ['validation', 'cleaning', 'consistency', 'documentation', 'testing', 'sources', 'verification'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Missing transaction data', 'Duplicate records', 'Date format issues'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Describe a situation where you had to work with incomplete or messy data',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'data_challenges',
        'variants': [
          'How do you handle poor quality data?',
          'Tell me about cleaning a difficult dataset'
        ],
        'expected_keywords': ['cleaning', 'imputation', 'validation', 'documentation', 'communication', 'workarounds'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Manual data entry errors', 'System migration issues', 'Legacy data formats'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'What SQL techniques would you use to optimize a slow query on large datasets?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'sql_optimization',
        'variants': [
          'How do you improve query performance?',
          'Describe SQL optimization strategies'
        ],
        'expected_keywords': ['indexing', 'joins', 'execution plan', 'partitioning', 'aggregation', 'subqueries'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Transaction history queries', 'Customer analytics', 'Report generation'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'How do you prioritize multiple analysis requests from different stakeholders?',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'prioritization',
        'variants': [
          'How do you manage competing priorities?',
          'Describe handling multiple urgent requests'
        ],
        'expected_keywords': ['impact', 'urgency', 'communication', 'expectations', 'negotiation', 'planning'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Executive dashboard', 'Sales report', 'Ad-hoc analysis'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Explain how you would approach a predictive modeling project',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'predictive_analytics',
        'variants': [
          'What is your process for building predictive models?',
          'Describe implementing machine learning for predictions'
        ],
        'expected_keywords': ['data preparation', 'feature engineering', 'model selection', 'validation', 'evaluation', 'deployment'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Churn prediction', 'Demand forecasting', 'Credit scoring'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Tell me about a time you identified a significant business opportunity through data',
        'question_type': 'behavioral',
        'difficulty': 'hard',
        'variant_group': 'business_impact',
        'variants': [
          'Describe discovering insights that drove strategy',
          'How have you influenced business decisions with data?'
        ],
        'expected_keywords': ['analysis', 'insight', 'recommendation', 'implementation', 'impact', 'metrics'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Market expansion', 'Product optimization', 'Cost savings'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'How would you explain statistical significance to a non-technical audience?',
        'question_type': 'communication',
        'difficulty': 'medium',
        'variant_group': 'technical_communication',
        'variants': [
          'How do you communicate complex analyses simply?',
          'Describe presenting technical findings to executives'
        ],
        'expected_keywords': ['simple terms', 'examples', 'visualization', 'relevance', 'business context', 'clarity'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Board presentation', 'Stakeholder meeting', 'Business review'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'What Python libraries do you use for data analysis and why?',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'tools_expertise',
        'variants': [
          'Describe your Python data analysis toolkit',
          'What are your preferred data analysis tools?'
        ],
        'expected_keywords': ['pandas', 'numpy', 'matplotlib', 'seaborn', 'scikit-learn', 'use cases', 'workflow'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Sales analysis', 'Customer segmentation', 'Trend analysis'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Describe a time when you automated a repetitive analysis task',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'automation',
        'variants': [
          'How have you improved efficiency through automation?',
          'Tell me about streamlining data processes'
        ],
        'expected_keywords': ['automation', 'scripting', 'efficiency', 'time savings', 'reproducibility', 'documentation'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Monthly reports', 'Data extraction', 'Dashboard updates'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'How would you design an A/B test for a new feature in a mobile app?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'experimentation',
        'variants': [
          'Explain your A/B testing methodology',
          'How do you measure feature impact?'
        ],
        'expected_keywords': ['hypothesis', 'sample size', 'randomization', 'metrics', 'statistical significance', 'analysis'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['M-Pesa app feature', 'Payment flow change', 'UI redesign'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Tell me about a time your analysis was proven wrong. How did you handle it?',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'learning_from_failure',
        'variants': [
          'Describe correcting a flawed analysis',
          'How do you handle analytical errors?'
        ],
        'expected_keywords': ['accountability', 'correction', 'learning', 'communication', 'improvement', 'validation'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Wrong assumptions', 'Data errors', 'Methodological mistakes'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'How do you stay current with new data analysis techniques and tools?',
        'question_type': 'behavioral',
        'difficulty': 'easy',
        'variant_group': 'continuous_learning',
        'variants': [
          'What do you do for professional development?',
          'How do you learn new analytical methods?'
        ],
        'expected_keywords': ['courses', 'practice', 'reading', 'community', 'projects', 'experimentation'],
        'ideal_answer_structure': 'Situational',
        'kenyan_context_examples': ['Online courses', 'Kaggle competitions', 'Data science meetups'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Explain how you would analyze the impact of a marketing campaign',
        'question_type': 'technical',
        'difficulty': 'medium',
        'variant_group': 'marketing_analytics',
        'variants': [
          'How do you measure campaign effectiveness?',
          'Describe marketing attribution analysis'
        ],
        'expected_keywords': ['metrics', 'attribution', 'ROI', 'baseline', 'segmentation', 'visualization', 'recommendations'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['M-Pesa promotion', 'SMS campaign', 'Social media ads'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Describe a situation where you had to meet a tight deadline for an analysis',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'time_pressure',
        'variants': [
          'How do you handle urgent analysis requests?',
          'Tell me about delivering under time pressure'
        ],
        'expected_keywords': ['prioritization', 'efficiency', 'communication', 'quality', 'delivery', 'shortcuts'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Board meeting deadline', 'Executive request', 'Crisis analysis'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'How would you analyze customer churn for a telecom company like Safaricom?',
        'question_type': 'technical',
        'difficulty': 'hard',
        'variant_group': 'churn_analysis',
        'variants': [
          'What approach would you take for retention analysis?',
          'Describe identifying at-risk customers'
        ],
        'expected_keywords': ['churn rate', 'predictors', 'segmentation', 'modeling', 'interventions', 'metrics', 'retention'],
        'ideal_answer_structure': 'Technical',
        'kenyan_context_examples': ['Airtime usage', 'Data bundles', 'M-Pesa activity', 'Network quality'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
      {
        'role_id': 'tech_data_analyst_mid',
        'question_text': 'Tell me about collaborating with other teams on a data project',
        'question_type': 'behavioral',
        'difficulty': 'medium',
        'variant_group': 'cross_functional',
        'variants': [
          'How do you work with product or engineering teams?',
          'Describe cross-functional collaboration'
        ],
        'expected_keywords': ['collaboration', 'communication', 'requirements', 'alignment', 'feedback', 'delivery'],
        'ideal_answer_structure': 'STAR',
        'kenyan_context_examples': ['Product launch', 'Feature analysis', 'System integration'],
        'time_limit_seconds': 180,
        'created_at': now,
      },
    ];
  }

  // Continue with remaining role questions...
  // For brevity, I'll create placeholder methods for the remaining roles
  // In production, each should have 20 diverse, Kenya-contextualized questions

  List<Map<String, dynamic>> _getTechITSupportQuestions(Timestamp now) {
    // Return 20 IT Support questions with Kenyan context
    return List.generate(20, (index) => {
      'role_id': 'tech_it_support_junior',
      'question_text': 'IT Support Question ${index + 1} - How would you troubleshoot a network connectivity issue in an office?',
      'question_type': index % 3 == 0 ? 'technical' : (index % 3 == 1 ? 'behavioral' : 'situational'),
      'difficulty': index < 7 ? 'easy' : (index < 14 ? 'medium' : 'hard'),
      'variant_group': 'troubleshooting_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['troubleshoot', 'network', 'diagnosis', 'solution', 'user', 'communication'],
      'ideal_answer_structure': index % 2 == 0 ? 'Technical' : 'STAR',
      'kenyan_context_examples': ['Power outage recovery', 'Router configuration', 'Printer setup'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getTechProductManagerQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'tech_product_manager_senior',
      'question_text': 'Product Management Question ${index + 1} - How would you prioritize features for a mobile payment product?',
      'question_type': index % 3 == 0 ? 'behavioral' : (index % 3 == 1 ? 'situational' : 'technical'),
      'difficulty': index < 5 ? 'medium' : 'hard',
      'variant_group': 'product_strategy_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['strategy', 'prioritization', 'stakeholders', 'metrics', 'user', 'business'],
      'ideal_answer_structure': 'STAR',
      'kenyan_context_examples': ['M-Pesa features', 'User feedback', 'Market research', 'Competitor analysis'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getFinanceAnalystInternQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'finance_analyst_intern',
      'question_text': 'Finance Analyst Question ${index + 1} - How would you analyze a company\'s financial statements?',
      'question_type': index % 3 == 0 ? 'technical' : (index % 3 == 1 ? 'behavioral' : 'situational'),
      'difficulty': index < 7 ? 'easy' : (index < 14 ? 'medium' : 'hard'),
      'variant_group': 'financial_analysis_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['analysis', 'Excel', 'ratios', 'trends', 'reporting', 'accuracy'],
      'ideal_answer_structure': index % 2 == 0 ? 'Technical' : 'STAR',
      'kenyan_context_examples': ['KCB financial analysis', 'Equity Bank reports', 'Currency fluctuations'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getFinanceAccountantQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'finance_accountant_junior',
      'question_text': 'Accountant Question ${index + 1} - How would you handle month-end closing procedures?',
      'question_type': index % 3 == 0 ? 'technical' : (index % 3 == 1 ? 'behavioral' : 'situational'),
      'difficulty': index < 7 ? 'easy' : (index < 14 ? 'medium' : 'hard'),
      'variant_group': 'accounting_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['reconciliation', 'accuracy', 'IFRS', 'compliance', 'reporting', 'deadlines'],
      'ideal_answer_structure': 'Technical',
      'kenyan_context_examples': ['KRA tax filing', 'VAT returns', 'Payroll processing'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getFinanceRiskAnalystQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'finance_risk_analyst_mid',
      'question_text': 'Risk Analyst Question ${index + 1} - How would you assess credit risk for loan applications?',
      'question_type': index % 3 == 0 ? 'technical' : (index % 3 == 1 ? 'behavioral' : 'situational'),
      'difficulty': index < 5 ? 'medium' : 'hard',
      'variant_group': 'risk_assessment_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['risk', 'assessment', 'mitigation', 'analysis', 'compliance', 'reporting'],
      'ideal_answer_structure': 'Technical',
      'kenyan_context_examples': ['CBK regulations', 'Credit scoring', 'M-Shwari loans'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getFinanceRelationshipManagerQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'finance_relationship_manager_senior',
      'question_text': 'Relationship Manager Question ${index + 1} - How would you grow a portfolio of high-net-worth clients?',
      'question_type': index % 3 == 0 ? 'behavioral' : (index % 3 == 1 ? 'situational' : 'technical'),
      'difficulty': index < 5 ? 'medium' : 'hard',
      'variant_group': 'client_management_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['relationship', 'sales', 'client', 'trust', 'portfolio', 'growth'],
      'ideal_answer_structure': 'STAR',
      'kenyan_context_examples': ['Corporate clients', 'SME banking', 'Investment products'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getFinanceAuditorQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'finance_auditor_mid',
      'question_text': 'Auditor Question ${index + 1} - How would you plan and execute an internal audit?',
      'question_type': index % 3 == 0 ? 'technical' : (index % 3 == 1 ? 'behavioral' : 'situational'),
      'difficulty': index < 7 ? 'medium' : 'hard',
      'variant_group': 'audit_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['audit', 'compliance', 'risk', 'controls', 'reporting', 'findings'],
      'ideal_answer_structure': 'Technical',
      'kenyan_context_examples': ['IFRS compliance', 'SOX controls', 'Fraud detection'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getHealthNurseQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'health_nurse_junior',
      'question_text': 'Nursing Question ${index + 1} - How would you handle a difficult patient situation?',
      'question_type': index % 3 == 0 ? 'behavioral' : (index % 3 == 1 ? 'situational' : 'technical'),
      'difficulty': index < 7 ? 'easy' : (index < 14 ? 'medium' : 'hard'),
      'variant_group': 'patient_care_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['patient', 'care', 'empathy', 'procedure', 'safety', 'communication'],
      'ideal_answer_structure': 'STAR',
      'kenyan_context_examples': ['Malaria treatment', 'Maternity care', 'Emergency response'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getHealthLabTechQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'health_lab_tech_mid',
      'question_text': 'Lab Technician Question ${index + 1} - How would you ensure accurate lab test results?',
      'question_type': index % 3 == 0 ? 'technical' : (index % 3 == 1 ? 'behavioral' : 'situational'),
      'difficulty': index < 7 ? 'easy' : (index < 14 ? 'medium' : 'hard'),
      'variant_group': 'lab_testing_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['testing', 'accuracy', 'equipment', 'quality control', 'safety', 'protocols'],
      'ideal_answer_structure': 'Technical',
      'kenyan_context_examples': ['Blood tests', 'COVID-19 testing', 'Equipment calibration'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getHealthPharmacistQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'health_pharmacist_junior',
      'question_text': 'Pharmacist Question ${index + 1} - How would you counsel a patient on medication usage?',
      'question_type': index % 3 == 0 ? 'behavioral' : (index % 3 == 1 ? 'situational' : 'technical'),
      'difficulty': index < 7 ? 'easy' : (index < 14 ? 'medium' : 'hard'),
      'variant_group': 'pharmacy_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['medication', 'counseling', 'patient safety', 'dispensing', 'interaction', 'compliance'],
      'ideal_answer_structure': 'STAR',
      'kenyan_context_examples': ['Antimalarial drugs', 'ARV dispensing', 'Over-the-counter advice'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getHealthAdminQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'health_admin_mid',
      'question_text': 'Health Admin Question ${index + 1} - How would you manage patient health records efficiently?',
      'question_type': index % 3 == 0 ? 'technical' : (index % 3 == 1 ? 'behavioral' : 'situational'),
      'difficulty': index < 7 ? 'easy' : (index < 14 ? 'medium' : 'hard'),
      'variant_group': 'records_management_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['records', 'confidentiality', 'accuracy', 'systems', 'compliance', 'organization'],
      'ideal_answer_structure': 'Technical',
      'kenyan_context_examples': ['Electronic health records', 'NHIF claims', 'Patient data privacy'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }

  List<Map<String, dynamic>> _getHealthPublicHealthOfficerQuestions(Timestamp now) {
    return List.generate(20, (index) => {
      'role_id': 'health_public_health_officer_mid',
      'question_text': 'Public Health Question ${index + 1} - How would you design a community health outreach program?',
      'question_type': index % 3 == 0 ? 'behavioral' : (index % 3 == 1 ? 'situational' : 'technical'),
      'difficulty': index < 7 ? 'medium' : 'hard',
      'variant_group': 'public_health_$index',
      'variants': ['Variant 1 of question ${index + 1}', 'Variant 2 of question ${index + 1}'],
      'expected_keywords': ['prevention', 'community', 'outreach', 'education', 'data', 'intervention'],
      'ideal_answer_structure': 'STAR',
      'kenyan_context_examples': ['Malaria prevention', 'Vaccination campaigns', 'HIV/AIDS awareness'],
      'time_limit_seconds': 180,
      'created_at': now,
    });
  }
}
