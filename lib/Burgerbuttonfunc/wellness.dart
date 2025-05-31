import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Center'),
        backgroundColor: const Color.fromARGB(255, 230, 26, 26),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Meditation Exercises'),
              _buildMeditationGrid(),
              const SizedBox(height: 20),
              _buildSectionTitle('Physical Exercises'),
              _buildExerciseGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.teal[800],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(String title, String duration, IconData icon,
      Color color, String demoUrl, bool isLottie, VoidCallback onTap) {
    return Card(
      elevation: 4,
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding from 12 to 8
          child: Column(
            mainAxisSize: MainAxisSize.min, // Added this line
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 90, // Reduced from 100 to 90
                child: isLottie
                    ? Lottie.network(
                        demoUrl,
                        controller: _controller,
                        onLoaded: (composition) {
                          _controller
                            ..duration = composition.duration
                            ..repeat();
                        },
                      )
                    : Image.network(
                        demoUrl,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(height: 4), // Reduced from 8 to 4
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14, // Reduced from 16 to 14
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2, // Add this to limit text to 2 lines
                overflow: TextOverflow.ellipsis, // Add this to handle overflow
              ),
              Text(
                duration,
                style: const TextStyle(fontSize: 12), // Reduced from 14 to 12
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85, // Adjusted from 0.8 to 0.85
      ),
      itemCount: meditationExercises.length,
      itemBuilder: (context, index) {
        return _buildExerciseCard(
          meditationExercises[index]['title']!,
          meditationExercises[index]['duration']!,
          meditationExercises[index]['icon']!,
          Colors.blue[100]!,
          meditationExercises[index]['demoUrl']!,
          meditationExercises[index]['isLottie']!,
          () => _showExerciseDetails(context, meditationExercises[index]),
        );
      },
    );
  }

  Widget _buildExerciseGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85, // Adjusted from 0.8 to 0.85
      ),
      itemCount: physicalExercises.length,
      itemBuilder: (context, index) {
        return _buildExerciseCard(
          physicalExercises[index]['title']!,
          physicalExercises[index]['duration']!,
          physicalExercises[index]['icon']!,
          Colors.green[100]!,
          physicalExercises[index]['demoUrl']!,
          physicalExercises[index]['isLottie']!,
          () => _showExerciseDetails(context, physicalExercises[index]),
        );
      },
    );
  }

  void _showExerciseDetails(
      BuildContext context, Map<String, dynamic> exercise) {
    late final AnimationController detailController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise['title']!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: exercise['isLottie']
                  ? Lottie.network(
                      exercise['demoUrl']!,
                      controller: detailController,
                      onLoaded: (composition) {
                        detailController
                          ..duration = composition.duration
                          ..repeat();
                      },
                    )
                  : Image.network(
                      exercise['demoUrl']!,
                      fit: BoxFit.contain,
                    ),
            ),
            const SizedBox(height: 10),
            Text('Duration: ${exercise['duration']}'),
            const SizedBox(height: 20),
            Text(
              exercise['description']!,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    ).then((_) {
      detailController.dispose();
    });
  }

  final List<Map<String, dynamic>> meditationExercises = [
    {
      'title': 'Breathing Meditation',
      'duration': '10 mins',
      'icon': Icons.air,
      'description':
          'Focus on your Breath meditation, also known as breath work meditation, is a practice that combines breathing exercises with mindfulness. It can help you relax, improve focus, and relieve stress. ',
      'demoUrl':
          'https://lottie.host/cbeaca5c-c2d4-4eb7-8fd5-cf277c37ba7e/zzRVJfgd2a.json',
      'isLottie': true,
    },
    {
      'title': 'Body Scan',
      'duration': '15 mins',
      'icon': Icons.accessibility_new,
      'description':
          'Progressive relaxation technique, A mindfulness meditation technique that involves scanning your body for sensations, pain or tension Its a way to reconnect with your body and become more aware of your physical and emotional state.',
      'demoUrl':
          'https://lottie.host/524fa76e-4781-4c35-b686-80a118e00ee1/ka2usRJ5wq.json',
      'isLottie': true,
    },
    {
      'title': 'Mindful Walking',
      'duration': '20 mins',
      'icon': Icons.directions_walk,
      'description':
          'Mindful walking is a practice that can help improve mental well-being by focusing on the present moment and engaging with your senses. It can help reduce stress, anxiety, and depression, and improve mood and concentration. ',
      'demoUrl':
          'https://lottie.host/1d854a84-d5dd-4e87-9d2e-ccd723528645/JcE1TW7OMN.json',
      'isLottie': true,
    },
    {
      'title': 'Guided Visualization',
      'duration': '15 mins',
      'icon': Icons.landscape,
      'description':
          'Guided visualization, also known as guided imagery, is a relaxation technique that can help with stress, anxiety, and self-confidence. It involves imagining yourself in a peaceful setting and using your senses to make the scene more vivid. ',
      'demoUrl':
          'https://lottie.host/32987002-eb42-4fd1-966e-249d9705671f/RbaESYJaMa.json',
      'isLottie': true,
    },
    {
      'title': 'Scripture Meditation',
      'duration': '15 mins',
      'icon': Icons.book,
      'description':
          'Scripture meditation is a Christian practice of reflecting on and becoming aware of Gods revelations through the Bible. Its a form of prayer that can help deepen a persons relationship with God and grow their faith. ',
      'demoUrl':
          'https://lottie.host/22f2bb3f-bd15-4143-a1f6-22dd50d024a4/oZ976NSzLR.json',
      'isLottie': true,
    },
    {
      'title': 'Prayer Time',
      'duration': '10 mins',
      'icon': Icons.favorite,
      'description':
          'Guided prayer session for spiritual connection and inner peace. Prayer can help improve mental health by reducing feelings of isolation, anxiety, and fear. It can also lift mood and positivity. ',
      'demoUrl':
          'https://lottie.host/b303b9e7-7731-49fd-90bd-661d902d10cb/GLzlNOKu2D.json',
      'isLottie': true,
    },
  ];

  final List<Map<String, dynamic>> physicalExercises = [
    {
      'title': 'Yoga Flow',
      'duration': '20 mins',
      'icon': Icons.self_improvement,
      'description':
          'Yoga poses and breathing exercises can help improve mental health by reducing stress, anxiety, and depression. Some yoga poses that can help with mental health include mood. ',
      'demoUrl':
          'https://lottie.host/83db614e-754f-40b0-8474-2bb7ad0bff70/8mDhlDhM9u.json',
      'isLottie': true,
    },
    {
      'title': 'Stress Relief Stretches',
      'duration': '10 mins',
      'icon': Icons.fitness_center,
      'description':
          'Stretching reduces the muscle tension, thereby reversing the cycle of tension, then tightening, and pain. Stretching has been shown to increase serotonin levels — i.e., the hormone that helps stabilize our mood, reduce stress, and overall makes us feel good — which causes a decrease in depression and anxiety.',
      'demoUrl':
          'https://lottie.host/78a18b0a-7060-4d2c-9a8f-a9ef307d93ef/PJXWyrgdMP.json',
      'isLottie': true,
    },
    {
      'title': 'Energy Boosting Workout',
      'duration': '15 mins',
      'icon': Icons.flash_on,
      'description':
          'Quick exercises to increase energy levels. Engaging in activities like walking, jogging, swimming, or using a treadmill can make you feel good! These exercises are not only fun but also keep your body and mind healthy and happy. Plus, going outside for your exercise can boost your mood even more!',
      'demoUrl': 'https://assets3.lottiefiles.com/packages/lf20_sz79nzyi.json',
      'isLottie': true,
    },
    {
      'title': 'Push Up',
      'duration': '10 mins',
      'icon': Icons.spa,
      'description':
          'The Push Up Challenge is a free mental health and fitness event that encourages people to complete push-ups to promote mental health awareness. The challenge can also help people connect with their community and engage in physical activity.  ',
      'demoUrl':
          'https://lottie.host/dfcaea8c-43d9-4a83-83d6-63ccdea14fb1/V88wDy0Amm.json',
      'isLottie': true,
    },
  ];
}
