import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/core/route.dart';
import 'package:server_box/data/model/server/server_private_info.dart';

final class IPerfPageArgs {
  final Spi spi;

  const IPerfPageArgs({required this.spi});
}

class IPerfPage extends StatefulWidget {
  final IPerfPageArgs args;

  const IPerfPage({super.key, required this.args});

  @override
  State<IPerfPage> createState() => _IPerfPageState();

  static const route = AppRouteArg<void, IPerfPageArgs>(
    page: IPerfPage.new,
    path: '/iperf',
  );
}

class _IPerfPageState extends State<IPerfPage> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('iperf'),
      ),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: 'iperf',
      child: const Icon(Icons.send),
      onPressed: () {
        if (_hostCtrl.text.isEmpty || _portCtrl.text.isEmpty) {
          context.showSnackBar(libL10n.empty);
          return;
        }
        AppRoutes.ssh(
          spi: widget.args.spi,
          initCmd: 'iperf -c ${_hostCtrl.text} -p ${_portCtrl.text}',
        ).go(context);
      },
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      children: [
        Input(
          controller: _hostCtrl,
          label: l10n.host,
          icon: Icons.computer,
          suggestion: false,
        ),
        Input(
          controller: _portCtrl,
          label: l10n.port,
          type: TextInputType.number,
          icon: Icons.numbers,
          suggestion: false,
        ),
      ],
    );
  }
}
