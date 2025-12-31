import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role_model.dart';
import '../services/firestore_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'question_list_screen.dart';

/// Screen for selecting a job role to practice
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Role> _allRoles = [];
  List<Role> _filteredRoles = [];
  bool _isLoading = true;
  String _selectedIndustry = 'All';
  String? _selectedDepartment;
  final TextEditingController _searchController = TextEditingController();

  // Industries
  final List<String> _industries = [
    'All',
    'Technology',
    'Finance',
    'Healthcare'
  ];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final roles = await _firestoreService.getAllRoles();

      setState(() {
        _allRoles = roles;
        _filteredRoles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading roles: $e')),
        );
      }
    }
  }

  void _filterRoles() {
    setState(() {
      _filteredRoles = _allRoles.where((role) {
        // Industry filter
        if (_selectedIndustry != 'All' &&
            role.industry != _selectedIndustry) {
          return false;
        }

        // Department filter
        if (_selectedDepartment != null &&
            role.department != _selectedDepartment) {
          return false;
        }

        // Search filter
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          return role.displayName.toLowerCase().contains(searchTerm) ||
              role.department.toLowerCase().contains(searchTerm);
        }

        return true;
      }).toList();
    });
  }

  List<String> _getDepartmentsForIndustry() {
    if (_selectedIndustry == 'All') {
      return _allRoles
          .map((role) => role.department)
          .toSet()
          .toList()
        ..sort();
    }

    return _allRoles
        .where((role) => role.industry == _selectedIndustry)
        .map((role) => role.department)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Industry Filter Chips
                const Text(
                  'Industry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _industries.map((industry) {
                    return FilterChip(
                      label: Text(industry),
                      selected: _selectedIndustry == industry,
                      onSelected: (selected) {
                        setState(() {
                          _selectedIndustry = industry;
                          _selectedDepartment = null;
                        });
                        _filterRoles();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Department Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: _selectedDepartment,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Departments'),
                    ),
                    ..._getDepartmentsForIndustry().map((dept) {
                      return DropdownMenuItem(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                    _filterRoles();
                  },
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search roles...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterRoles();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => _filterRoles(),
                ),
              ],
            ),
          ),

          // Roles List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRoles.isEmpty
                    ? _buildEmptyState()
                    : _buildRolesList(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No roles found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedIndustry = 'All';
                _selectedDepartment = null;
                _searchController.clear();
              });
              _filterRoles();
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    // Use GridView on tablets, ListView on phones
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredRoles.length,
        itemBuilder: (context, index) {
          return _buildRoleCard(_filteredRoles[index]);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRoles.length,
      itemBuilder: (context, index) {
        return _buildRoleCard(_filteredRoles[index]);
      },
    );
  }

  Widget _buildRoleCard(Role role) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToQuestions(role),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role Name
              Text(
                role.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Department
              Text(
                role.department,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              // Company Examples
              if (role.kenyanCompanies.isNotEmpty)
                Text(
                  role.kenyanCompanies.take(3).join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Question Count Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.question_answer,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${role.questionCount} questions',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _navigateToQuestions(role),
                    child: const Text('Start Practice'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToQuestions(Role role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionListScreen(role: role),
      ),
    );
  }
}
