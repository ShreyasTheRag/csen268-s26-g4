import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:santa_clara/blocs/trip.dart';

import '../../widgets/full_width_button.dart';
import '../../widgets/horizontal_scroll_list.dart';
import '../../widgets/location_card.dart';
import '../../widgets/removable_image_card.dart';
import '../../widgets/section_label.dart';

class PlanTripPage extends StatelessWidget {
  const PlanTripPage({super.key});
@override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripBloc(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF335C1F),
          elevation: 0,
          leading: const Icon(Icons.menu, color: Colors.white),
          title: const Text('Plan a Trip', style: TextStyle(color: Colors.white)),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.account_circle, color: Colors.white, size: 30),
            )
          ],
        ),
        body: BlocBuilder<TripBloc, TripState>(
          builder: (context, state) {
            // Pull the trip object from your state
            final trip = state.trip;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('SELECT A TRIP'),
                  // Pass the name from the state
                  _buildTripDropdown(trip.name), 
                  const SizedBox(height: 20),

                  const SectionLabel('LOCATION PLANNED'),
                  HorizontalScrollList(
                    height: 100,
                    itemCount: 5,
                    itemBuilder: (context, index) => const LocationCard(
                      locationName: 'Location',
                      imageAsset: 'assets/car.png',
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionLabel('ROUTE'),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      image: const DecorationImage(
                        image: AssetImage('car.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FullWidthButton(
                    text: 'Add Location',
                    onPressed: () {},
                    color: const Color(0xFF558B2F),
                  ),
                  const SizedBox(height: 20),

                  // Use real dates from the state
                  _buildDatePicker(context, 'START DATE', trip.startDate, true),
                  _buildDatePicker(context, 'END DATE', trip.endDate, false),
                  const SizedBox(height: 20),

                  const SectionLabel('YOUR IMAGES'),
                  HorizontalScrollList(
                    height: 100,
                    itemCount: 10,
                    itemBuilder: (context, index) => const RemovableImageCard(
                      imageAsset: 'assets/car.png', // TODO: update for different images
                    ),
                  ),
                  const SizedBox(height: 12),
                  FullWidthButton(
                    text: 'Add Photo',
                    onPressed: () {},
                    color: const Color(0xFF558B2F),
                  ),
                  const SizedBox(height: 20),

                  const SectionLabel('SUPPLIES BROUGHT'),
                  HorizontalScrollList(
                    height: 100,
                    itemCount: 4,
                    itemBuilder: (context, index) => const RemovableImageCard(
                      imageAsset: 'assets/car.png',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FullWidthButton(
                    text: 'Add Supply',
                    onPressed: () {},
                    color: const Color(0xFF558B2F),
                  ),
                  const SizedBox(height: 20),

                  const SectionLabel('TRIP NOTES'),
                  _buildNotesBox(trip.notes), 
                  const SizedBox(height: 20),

                  const SectionLabel('FRIENDS'),
                  _buildFriendsList(),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: FullWidthButton(
                          text: 'Finished Trip',
                          color: const Color(0xFF558B2F),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FullWidthButton(
                          text: 'Delete Trip',
                          color: const Color(0xFF335C1F),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // UI Helper methods to keep the build method clean
  Widget _buildTripDropdown(String currentTripName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentTripName, // Use the name from BLoC state
          isExpanded: true,
          items: ['Trip Name 1', 'Trip Name 2']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            // TODO: Dispatch Bloc event to update selected trip
          },
        ),
      ),
    );
  }

  Widget _buildNotesBox(String initialNotes) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      // Scrollbar and SingleChildScrollView ensure notes are scrollable
      child: Scrollbar(
        child: TextField(
          controller: TextEditingController(text: initialNotes),
          maxLines: null,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter trip notes here...',
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        GestureDetector(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildFriendsList() {
    return Row(
      children: [
        ...List.generate(5, (index) => const Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Icon(Icons.account_circle, size: 36),
        )),
        Icon(Icons.add_circle, color: Colors.grey.shade300, size: 36),
      ],
    );
  }

  void _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF558B2F),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // TODO
    }
  }
}