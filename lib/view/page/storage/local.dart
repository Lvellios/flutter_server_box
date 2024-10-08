import 'dart:io';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/data/model/server/server_private_info.dart';
import 'package:server_box/data/model/sftp/worker.dart';
import 'package:server_box/data/provider/server.dart';
import 'package:server_box/data/provider/sftp.dart';
import 'package:server_box/data/res/misc.dart';
import 'package:server_box/view/widget/omit_start_text.dart';

import 'package:server_box/core/route.dart';
import 'package:server_box/data/model/app/path_with_prefix.dart';

class LocalStoragePage extends StatefulWidget {
  final bool isPickFile;
  final String? initDir;
  const LocalStoragePage({
    super.key,
    required this.isPickFile,
    this.initDir,
  });

  @override
  State<LocalStoragePage> createState() => _LocalStoragePageState();
}

class _LocalStoragePageState extends State<LocalStoragePage> {
  LocalPath? _path;

  final _sortType = ValueNotifier(_SortType.name);

  @override
  void initState() {
    super.initState();
    if (widget.initDir != null) {
      setState(() {
        _path = LocalPath(widget.initDir!);
      });
    } else {
      setState(() {
        _path = LocalPath(Paths.file);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const BackButtonIcon(),
          onPressed: () {
            if (_path != null) {
              _path!.update('/');
            }
            context.pop();
          },
        ),
        title: Text(libL10n.file),
        actions: [
          IconButton(
            icon: const Icon(Icons.downloading),
            onPressed: () => AppRoutes.sftpMission().go(context),
          ),
          ValBuilder<_SortType>(
            listenable: _sortType,
            builder: (value) {
              return PopupMenuButton<_SortType>(
                icon: const Icon(Icons.sort),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: _SortType.name,
                      child: Text(libL10n.name),
                    ),
                    PopupMenuItem(
                      value: _SortType.size,
                      child: Text(l10n.size),
                    ),
                    PopupMenuItem(
                      value: _SortType.time,
                      child: Text(l10n.time),
                    ),
                  ];
                },
                onSelected: (value) {
                  _sortType.value = value;
                },
              );
            },
          ),
        ],
      ),
      body: FadeIn(
        key: UniqueKey(),
        child: ValBuilder(
          listenable: _sortType,
          builder: (val) {
            return _buildBody();
          },
        ),
      ),
      bottomNavigationBar: SafeArea(child: _buildPath()),
    );
  }

  Widget _buildPath() {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 7, 11, 11),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OmitStartText(_path?.path ?? '...'),
          _buildBtns(),
        ],
      ),
    );
  }

  Widget _buildBtns() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          onPressed: () {
            _path?.update('..');
            setState(() {});
          },
          icon: const Icon(Icons.arrow_back),
        ),
        IconButton(
          onPressed: () async {
            final path = await Pfs.pickFilePath();
            if (path == null) return;
            final name = path.getFileName() ?? 'imported';
            await File(path).copy(_path!.path.joinPath(name));
            setState(() {});
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_path == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final dir = Directory(_path!.path);
    final tempFiles = dir.listSync();
    final files = _sortType.value.sort(tempFiles);
    return ListView.builder(
      itemCount: files.length,
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = file.path.split('/').last;
        final stat = file.statSync();
        final isDir = stat.type == FileSystemEntityType.directory;

        return CardX(
          child: ListTile(
            leading: isDir
                ? const Icon(Icons.folder_open)
                : const Icon(Icons.insert_drive_file),
            title: Text(fileName),
            subtitle:
                isDir ? null : Text(stat.size.bytes2Str, style: UIs.textGrey),
            trailing: Text(
              stat.modified
                  .toString()
                  .substring(0, stat.modified.toString().length - 4),
              style: UIs.textGrey,
            ),
            onLongPress: () {
              if (!isDir) return;
              _showDirActionDialog(file);
            },
            onTap: () async {
              if (!isDir) {
                await _showFileActionDialog(file);
                return;
              }
              _path!.update(fileName);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Future<void> _showDirActionDialog(FileSystemEntity file) async {
    context.showRoundDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              context.pop();
              _showRenameDialog(file);
            },
            title: Text(libL10n.rename),
            leading: const Icon(Icons.abc),
          ),
          ListTile(
            onTap: () {
              context.pop();
              _showDeleteDialog(file);
            },
            title: Text(libL10n.delete),
            leading: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _showFileActionDialog(FileSystemEntity file) async {
    final fileName = file.path.split('/').last;
    if (widget.isPickFile) {
      await context.showRoundDialog(
        title: libL10n.file,
        child: Text(fileName),
        actions: [
          Btn.ok(onTap: () {
            context.pop();
            context.pop(file.path);
          }),
        ],
      );
      return;
    }
    context.showRoundDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(libL10n.edit),
            onTap: () async {
              context.pop();
              final stat = await file.stat();
              if (stat.size > Miscs.editorMaxSize) {
                context.showRoundDialog(
                  title: libL10n.attention,
                  child: Text(l10n.fileTooLarge(fileName, stat.size, '1m')),
                );
                return;
              }
              final result = await AppRoutes.editor(
                path: file.absolute.path,
              ).go<bool>(context);
              if (result == true) {
                context.showSnackBar(l10n.saved);
                setState(() {});
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.abc),
            title: Text(libL10n.rename),
            onTap: () {
              context.pop();
              _showRenameDialog(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(libL10n.delete),
            onTap: () {
              context.pop();
              _showDeleteDialog(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: Text(l10n.upload),
            onTap: () async {
              context.pop();

              final spi = await context.showPickSingleDialog<Spi>(
                title: libL10n.select,
                items: ServerProvider.serverOrder.value
                    .map((e) => ServerProvider.pick(id: e)?.value.spi)
                    .whereType<Spi>()
                    .toList(),
                display: (e) => e.name,
              );
              if (spi == null) return;

              final remotePath = await AppRoutes.sftp(
                spi: spi,
                isSelect: true,
              ).go<String>(context);
              if (remotePath == null) {
                return;
              }

              SftpProvider.add(SftpReq(
                spi,
                '$remotePath/$fileName',
                file.absolute.path,
                SftpReqType.upload,
              ));
              context.showSnackBar(l10n.added2List);
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(libL10n.open),
            onTap: () {
              Pfs.share(path: file.absolute.path);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(FileSystemEntity file) {
    final fileName = file.path.split('/').last;
    context.showRoundDialog(
      title: libL10n.rename,
      child: Input(
        autoFocus: true,
        controller: TextEditingController(text: fileName),
        suggestion: true,
        onSubmitted: (p0) {
          context.pop();
          final newPath = '${file.parent.path}/$p0';
          try {
            file.renameSync(newPath);
          } catch (e) {
            context.showSnackBar('${libL10n.fail}:\n$e');
            return;
          }

          setState(() {});
        },
      ),
    );
  }

  void _showDeleteDialog(FileSystemEntity file) {
    final fileName = file.path.split('/').last;
    context.showRoundDialog(
      title: libL10n.delete,
      child: Text(libL10n.askContinue('${libL10n.delete} $fileName')),
      actions: Btn.ok(
        onTap: () async {
          context.pop();
          try {
            await file.delete(recursive: true);
          } catch (e) {
            context.showSnackBar('${libL10n.fail}:\n$e');
            return;
          }
          setState(() {});
        },
      ).toList,
    );
  }
}

enum _SortType {
  name,
  size,
  time,
  ;

  List<FileSystemEntity> sort(List<FileSystemEntity> files) {
    switch (this) {
      case _SortType.name:
        files.sort((a, b) => a.path.compareTo(b.path));
        break;
      case _SortType.size:
        files.sort((a, b) => a.statSync().size.compareTo(b.statSync().size));
        break;
      case _SortType.time:
        files.sort(
            (a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        break;
    }
    return files;
  }
}
