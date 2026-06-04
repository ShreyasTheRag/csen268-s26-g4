import 'package:flutter/material.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:santa_clara/models/vehicle.dart';
import 'package:santa_clara/pages/yourVehicle/vehicle_cubit.dart';
import 'package:santa_clara/widgets/add_things_button.dart';
import 'package:santa_clara/widgets/body_text.dart';
import 'package:santa_clara/widgets/hero_section.dart';
import 'package:santa_clara/widgets/photo_gallery.dart';
import 'package:santa_clara/widgets/section_label.dart';
import 'package:santa_clara/widgets/triad.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class YourVehiclePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
    // Replace 'current_logged_in_user_id' with your actual app authentication user ID string
      create: (context) => VehicleCubit(),
      child: const YourVehiclePageBody(),
    );
  }
}

class VehicleInputForm extends StatefulWidget {
  final Function(String vin) onSave;

  const VehicleInputForm({super.key, required this.onSave});

  @override
  State<VehicleInputForm> createState() => _VehicleInputFormState();
}

class _VehicleInputFormState extends State<VehicleInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _vinController = TextEditingController();

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon matching your Santa Clara app camping aesthetic
              const Icon(
                Icons.directions_car_filled,
                size: 72,
                color: Color(0xFF386625),
              ),
              const SizedBox(height: 16),
              const Text(
                "Link Your Adventure Rig",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF386625),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter your vehicle's 17-digit VIN (found on your windshield base or driver's side doorjamb). We will automatically pull factory drivetrain and clearance specs from the NHTSA registry.",
                style: TextStyle(color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // VIN Input Field
              TextFormField(
                controller: _vinController,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                maxLength: 17, // Prevents entering extra characters
                decoration: const InputDecoration(
                  labelText: '17-Digit VIN',
                  hintText: 'e.g., ABCD1234EFGH56789',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin, color: Color(0xFF386625)),
                  counterText: "", // Hides the default character counter text underneath
                ),
                // Custom validation rule structure
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a VIN string';
                  }
                  
                  // Strip spaces to evaluate true tracking character count length
                  final cleanValue = value.replaceAll(' ', '');
                  if (cleanValue.length != 17) {
                    return 'A standard vehicle VIN must be exactly 17 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Submit Action Trigger Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF386625),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Send the parsed text payload out to the Parent Widget context
                    widget.onSave(_vinController.text.trim());
                  }
                },
                child: const Text(
                  'Decode & Fetch Rig Specs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YourVehiclePageBody extends StatelessWidget {
  const YourVehiclePageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF386625),
        title: const Text('Your Vehicle', style: TextStyle(color: Colors.white)),
      ),
      body: BlocBuilder<VehicleCubit, VehicleState>(
        builder: (context, state) {
          
          // State 1: Loading wheel active
          if (state is VehicleLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF386625)));
          }

          // State 2: Display error message with a retry option
          if (state is VehicleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<VehicleCubit>().checkSavedVehicle(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // State 3: User hasn't registered a car. Render the clean 1-field VIN Form
          if (state is NoVehicleSaved) {
            return VehicleInputForm(
              onSave: (vin) {
                // Call the cubit function directly
                context.read<VehicleCubit>().saveVehicle(vin);
              },
            );
          }

          // State 4: Vehicle loaded! Inject actual specs right into your layout skeleton
          if (state is VehicleLoaded) {
            final vehicle = state.vehicle;
            final accessories = vehicle.getRecommendedAccessories();
            String accessoriesString = accessories.map((item) => "• ${item['name']}: ${item['reason']}").join("\n\n");

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10.0,
                children: [
                  HeroSection(title: "${vehicle.year} ${vehicle.make} ${vehicle.model}"),
                  const PhotoGallery(),
                  Triad(
                    keys: const ["Drive Type", "Class Type", "Rating"], 
                    values: [vehicle.driveType.split('/')[0], vehicle.vehicleType.split(' ')[0], "5 / 5"]
                  ),
                  const SectionLabel("Warnings"),
                  BodyText(text: vehicle.driveType.toLowerCase().contains('4wd') ? "None" : "Caution: Low ground clearance or 2WD drivetrain configuration."),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAccessoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add recommended accessories?"),
        actions: [
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext), child: const Text("No")),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext), child: const Text("Yes")),
        ],
      ),
    );
  }
}