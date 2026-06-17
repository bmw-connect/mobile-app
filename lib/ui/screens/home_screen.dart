import 'package:flutter/material.dart';
import '../widgets/connection_banner.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/source_switcher.dart';
import '../widgets/toggle_row.dart';
import '../widgets/volume_control.dart';
import '../widgets/vu_meters.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(child: NowPlayingCard()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: SourceSwitcher()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: VolumeControl()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: DspToggleRow()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: VuMetersWidget()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
              sliver: SliverToBoxAdapter(child: StatsBar()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'carplay-audio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                'BMW E46 · HiFiBerry DAC',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          const ConnectionBanner(),
        ],
      ),
    );
  }
}
