import 'dart:async';

import 'package:catmovie/app/modules/home/views/auto_update.dart';
import 'package:catmovie/app/widget/k_body.dart';
import 'package:catmovie/app/widget/window_appbar.dart';
import 'package:catmovie/app/widget/zoom.dart';
import 'package:catmovie/utils/boop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:catmovie/app/extension.dart';
import 'package:catmovie/app/modules/home/controllers/home_controller.dart';
import 'package:catmovie/app/modules/home/views/parse_vip_manage.dart';
import 'package:catmovie/app/modules/home/views/source_help.dart';
import 'package:catmovie/app/shared/bus.dart';
import 'package:catmovie/git_info.dart';
import 'package:catmovie/shared/enum.dart';
import 'package:catmovie/shared/manage.dart';
import 'package:catmovie/app/modules/home/views/cupertino_license.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:settings_ui/settings_ui.dart';

import 'package:xi/xi.dart';

const kTelegramGroup = "https://t.me/catmovie1145";

const kGithubIconSvg = r"""
<svg t="1757744978460" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="13267" width="200" height="200"><path d="M512 42.666667A464.64 464.64 0 0 0 42.666667 502.186667 460.373333 460.373333 0 0 0 363.52 938.666667c23.466667 4.266667 32-9.813333 32-22.186667v-78.08c-130.56 27.733333-158.293333-61.44-158.293333-61.44a122.026667 122.026667 0 0 0-52.053334-67.413333c-42.666667-28.16 3.413333-27.733333 3.413334-27.733334a98.56 98.56 0 0 1 71.68 47.36 101.12 101.12 0 0 0 136.533333 37.973334 99.413333 99.413333 0 0 1 29.866667-61.44c-104.106667-11.52-213.333333-50.773333-213.333334-226.986667a177.066667 177.066667 0 0 1 47.36-124.16 161.28 161.28 0 0 1 4.693334-121.173333s39.68-12.373333 128 46.933333a455.68 455.68 0 0 1 234.666666 0c89.6-59.306667 128-46.933333 128-46.933333a161.28 161.28 0 0 1 4.693334 121.173333A177.066667 177.066667 0 0 1 810.666667 477.866667c0 176.64-110.08 215.466667-213.333334 226.986666a106.666667 106.666667 0 0 1 32 85.333334v125.866666c0 14.933333 8.533333 26.88 32 22.186667A460.8 460.8 0 0 0 981.333333 502.186667 464.64 464.64 0 0 0 512 42.666667" fill="#231F20" p-id="13268"></path></svg>
""";

enum GetBackResultType {
  /// 失败
  fail,

  /// 成功
  success
}

enum HandleDiglogTapType {
  /// 清空
  clean,

  /// 获取配置
  kget,
}

GlobalKey kVideoKernelBtnKey = GlobalKey();

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with AutomaticKeepAliveClientMixin {
  final HomeController home = Get.find<HomeController>();

  late StreamSubscription $$bus;

  Future<String> loadAsset() async {
    return await rootBundle.loadString('assets/data/source_help.txt');
  }

  String sourceHelpText = "";

  bool _isDark = false;

  bool get isDark {
    return _isDark;
  }

  set isDark(bool newVal) {
    updateSetting(
      SettingsAllKey.themeMode,
      newVal ? SystemThemeMode.dark : SystemThemeMode.light,
    );
    setState(() {
      _isDark = newVal;
    });
    Get.changeThemeMode(newVal ? ThemeMode.dark : ThemeMode.light);
  }

  bool _autoDarkMode = false;

  VideoKernel _videoKernel = VideoKernel.webview;

  bool _hapticFeedback = true;

  bool get hapticFeedback => _hapticFeedback;
  set hapticFeedback(bool flag) {
    boop.call(HapticsType.selection, force: true);
    boop.setEnabled(flag);
    _hapticFeedback = flag;
    if (mounted) setState(() {});
  }

  set autoDarkMode(bool newVal) {
    if (newVal) {
      updateSetting(SettingsAllKey.themeMode, SystemThemeMode.system);
    }
    setState(() {
      _autoDarkMode = newVal;
    });
    if (!newVal) {
      _isDark = Get.isPlatformDarkMode;
      Get.changeThemeMode(!_isDark ? ThemeMode.light : ThemeMode.dark);
      return;
    }
    if (GetPlatform.isWindows) {
      var mode = getWindowsThemeMode();
      Get.changeTheme(ThemeData(brightness: mode));
    }
    Get.changeThemeMode(ThemeMode.system);
  }

  bool get autoDarkMode {
    return _autoDarkMode;
  }

  @override
  void initState() {
    setState(() {
      var themeMode =
          getSettingAsKeyIdent<SystemThemeMode>(SettingsAllKey.themeMode);
      _isDark = themeMode.isDark;
      _autoDarkMode = themeMode.isSytem;
      _videoKernel =
          getSettingAsKeyIdent<VideoKernel>(SettingsAllKey.videoKernel);
      _mirrorLength = SpiderManage.data.length;
      // var __hapticFeedback = getSettingAsKeyIdent<bool>(
      //   SettingsAllKey.hapticFeedback,
      //   defaultValue: true,
      // );
      // _hapticFeedback = __hapticFeedback;
      // boop.enabled = _hapticFeedback;
      _hapticFeedback = boop.enabled; // 初始化已经在 initHapticFeedback 中做了
    });
    loadSourceHelp();
    addMirrorMangerTextareaLister();
    $$bus = $bus.on<SettingEvent>().listen((event) {
      updateNSFW(event.nsfw, onlyUpdate: true);
    });
    super.initState();
  }

  @override
  void dispose() {
    _editingController.dispose();
    $$bus.cancel();
    super.dispose();
  }

  void updateNSFW(bool flag, {bool onlyUpdate = false}) {
    home.isNsfw = flag;
    if (!onlyUpdate) {
      showNSFW = flag;
    }
    boop.selection();
    home.update();
  }

  void addMirrorMangerTextareaLister() {
    editingControllerValue =
        getSettingAsKeyIdent<String>(SettingsAllKey.mirrorTextarea);
    _editingController.addListener(() {
      updateSetting(SettingsAllKey.mirrorTextarea, editingControllerValue);
    });
  }

  Future<void> loadSourceHelp() async {
    var data = await loadAsset();
    setState(() {
      sourceHelpText = data;
    });
  }

  bool get showNSFW {
    return (home.isNsfw || nShowNSFW >= 10);
  }

  set showNSFW(bool newVal) {
    setState(() {
      nShowNSFW = !newVal ? 0 : 10;
    });
  }

  int _nShowNSFW = 0;

  int get nShowNSFW => _nShowNSFW;

  set nShowNSFW(int newVal) {
    setState(() {
      _nShowNSFW = newVal;
    });
  }

  int _mirrorLength = 0;

  String get mirrorLengthWithText {
    if (_mirrorLength == 0) {
      return "暂无";
    }
    return _mirrorLength.toString();
  }

  // NOTE(d1y): 这里的 home.parseVipList 会动态更新吗?
  String get parseVipListWithText {
    if (home.parseVipList.isEmpty) {
      return "暂无";
    }
    return home.parseVipList.length.toString();
  }

  final TextEditingController _editingController = TextEditingController();

  String get editingControllerValue {
    return _editingController.text.trim();
  }

  set editingControllerValue(String newVal) {
    _editingController.text = newVal;
  }

  Future<void> handleDiglogTap(HandleDiglogTapType type) async {
    switch (type) {
      case HandleDiglogTapType.clean:
        editingControllerValue = "";
        EasyLoading.showInfo("解析内容已经清空!");
        boop.success();
        break;
      case HandleDiglogTapType.kget:
        if (editingControllerValue.isEmpty) {
          EasyLoading.showError("内容为空, 请填写url!");
          boop.error();
          return;
        }
        var target = SourceUtils.getSources(editingControllerValue);
        if (target.isEmpty) {
          EasyLoading.showError("没有找到匹配的源!");
          boop.error();
          return;
        }
        Get.dialog(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Column(
                spacing: 42,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  CupertinoButton.filled(
                    child: const Text(
                      "关闭",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
          ),
          barrierColor: CupertinoColors.black.withValues(alpha: .9),
        );
        var data = await SourceUtils.runTaks(target);
        Get.back();
        if (data.isEmpty) {
          EasyLoading.showError("获取的内容为空!");
          boop.error();
          return;
        }
        SpiderManage.extend.clear();
        SpiderManage.extend.addAll(data);
        SpiderManage.saveToCache(SpiderManage.extend);
        var showMessage = "已同步成功(${data.length}个源)!";
        updateSetting(SettingsAllKey.onBoardingShowed, true);
        EasyLoading.showSuccess(showMessage);
        _mirrorLength = data.length;
        if (mounted) setState(() {});
        boop.success();
        break;
      default:
    }
  }

  void handleCleanCache() {
    boop.success();
    home.clearCache();
    home.confirmAlert(
      "已删除缓存, 部分内容重启之后生效!",
      showCancel: false,
      confirmText: "我知道了",
      context: context,
    );
    _mirrorLength = 0;
    if (mounted) setState(() {});
  }

  List<PullDownMenuEntry> _buildVideoKernel() {
    void action(VideoKernel vk) {
      _videoKernel = vk;
      updateSetting(SettingsAllKey.videoKernel, vk);
      setState(() {});
      boop.selection();
    }

    var result = [VideoKernel.webview, VideoKernel.mediaKit].map((item) {
      return PullDownMenuItem.selectable(
        selected: item == _videoKernel,
        onTap: () => action(item),
        title: item.name,
      );
    }).toList();
    if (GetPlatform.isMacOS) {
      result.add(
        PullDownMenuItem.selectable(
          selected: VideoKernel.iina == _videoKernel,
          onTap: () {
            boop.success();
            final bool isInstall = checkInstalledIINA();
            if (!isInstall) {
              EasyLoading.showError("未安装IINA, 请先安装!");
              boop.error();
              return;
            }
            action(VideoKernel.iina);
          },
          title: VideoKernel.iina.name,
        ),
      );
    }
    return result;
  }

  void handleSourceHelp() {
    var cx = getSettingAsKeyIdent<String>(SettingsAllKey.mirrorTextarea,
            defaultValue: "")
        .trim();
    if (cx.isNotEmpty && cx != editingControllerValue) {
      editingControllerValue = cx;
    }
    var fullWidth = context.mediaQuery.size.width;
    var width = fullWidth * .48;
    if (fullWidth <= 700) {
      width = 620;
    }
    Get.defaultDialog(
      actions: [
        Zoom(
          child: CupertinoButton.filled(
            sizeStyle: CupertinoButtonSize.small,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: const Text("清空"),
            onPressed: () {
              handleDiglogTap(HandleDiglogTapType.clean);
            },
          ),
        ),
        Zoom(
          child: CupertinoButton.filled(
            sizeStyle: CupertinoButtonSize.small,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: const Text("获取配置"),
            onPressed: () {
              boop.selection();
              handleDiglogTap(HandleDiglogTapType.kget);
            },
          ),
        ),
      ],
      titlePadding: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 9,
      ),
      title: "我的视频源网络地址",
      titleStyle: TextStyle(
        fontSize: 16,
        color: context.isDarkMode ? Colors.white : Colors.black,
      ),
      content: SizedBox(
        height: Get.height * .2,
        width: width,
        child: Card(
          color: const Color.fromRGBO(0, 0, 0, 1),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _editingController,
              maxLines: 32,
              style: TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration.collapsed(
                hintText: sourceHelpText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void handleCleanCacheBefore(BuildContext ctx) {
    boop.warning();
    showCupertinoDialog(
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: const Text("将删除所有缓存, 包括视频源和一些设置"),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text(
              '我想想',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            onPressed: () {
              boop.selection();
              Get.back();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              handleCleanCache();
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      context: ctx,
    );
  }

  Widget leadingIcon(String icon, {double? width, double? height}) {
    return Builder(
      builder: (context) {
        return SvgPicture.string(
          icon,
          colorFilter: ColorFilter.mode(
            SettingsTheme.of(context).themeData.leadingIconsColor ??
                Colors.transparent,
            BlendMode.srcIn,
          ),
          width: width ?? 24,
          height: height ?? 24,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: WindowAppBar(
        title: Text(
          "设置",
          style: TextStyle(
            fontSize: 16,
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [SizedBox.shrink()],
      ),
      body: ScrollConfiguration(
        behavior: ScrollBehavior().copyWith(scrollbars: false),
        child: SettingsList(
          applicationType: ApplicationType.cupertino,
          lightTheme:
              SettingsThemeData(settingsListBackground: Colors.transparent),
          darkTheme:
              SettingsThemeData(settingsListBackground: Colors.transparent),
          sections: [
            SettingsSection(
              title: Text('常规设置'),
              tiles: <SettingsTile>[
                if (!autoDarkMode)
                  SettingsTile.switchTile(
                    onToggle: (value) {
                      isDark = value;
                      boop.success();
                    },
                    onPressed: (cx) {
                      isDark = !isDark;
                      boop.success();
                    },
                    initialValue: isDark,
                    // leading: Icon(Icons.settings_brightness),
                    leading: leadingIcon(r"""
<svg t="1758540863532" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="37254" width="200" height="200"><path d="M512 128c17.7664 0 20.6848 26.624 5.4784 35.84A249.6 249.6 0 1 0 860.16 506.5216c9.216-15.2064 35.84-12.288 35.84 5.4784A384 384 0 1 1 512 128z m120.32 235.3664a18.5344 18.5344 0 0 1 34.56 0l5.9904 15.36c1.8944 4.8128 5.6832 8.6016 10.4448 10.496l15.3088 6.0416a18.6368 18.6368 0 0 1 0 34.6624l-15.3088 6.0416a18.5856 18.5856 0 0 0-10.4448 10.496l-5.9904 15.36a18.5344 18.5344 0 0 1-34.56 0l-6.0416-15.36a18.5856 18.5856 0 0 0-10.4448-10.496l-15.2576-6.0416a18.6368 18.6368 0 0 1 0-34.6624l15.2576-6.0416a18.5856 18.5856 0 0 0 10.4448-10.496z m180.992-227.4816l2.048 3.8912 16.5376 42.0864c1.3824 3.584 3.8912 6.656 7.0656 8.704l3.3792 1.792 41.8816 16.5888c14.2848 5.632 15.5648 24.576 3.8912 32.6144l-3.8912 2.048-41.8816 16.5888a18.5856 18.5856 0 0 0-8.704 7.1168l-1.7408 3.3792-16.5376 42.0352a18.5344 18.5344 0 0 1-32.4608 3.9424l-2.048-3.9424-16.5376-42.0352a18.5856 18.5856 0 0 0-7.0656-8.704l-3.4304-1.792-41.8816-16.5888a18.688 18.688 0 0 1-3.8912-32.6144l3.8912-2.048 41.8816-16.5888a18.5856 18.5856 0 0 0 8.704-7.1168l1.792-3.3792 16.4864-42.0864a18.5344 18.5344 0 0 1 32.512-3.8912z" p-id="37255"></path></svg>
"""),
                    title: Text('暗色主题'),
                  ),
                SettingsTile.switchTile(
                  onToggle: (value) {
                    autoDarkMode = value;
                    boop.success();
                  },
                  onPressed: (cx) {
                    autoDarkMode = !autoDarkMode;
                    boop.success();
                  },
                  initialValue: autoDarkMode,
                  // leading: Icon(CupertinoIcons.moon_stars_fill),
                  leading: leadingIcon(r"""
<svg t="1758540309330" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="21793" width="200" height="200"><path d="M469.504 42.496a42.496 42.496 0 1 1 84.992 0v43.008a42.496 42.496 0 1 1-84.992 0zM469.504 938.496a42.496 42.496 0 1 1 84.992 0v43.008a42.496 42.496 0 0 1-84.992 0zM1024 512a42.496 42.496 0 0 0-42.496-42.496h-43.008a42.496 42.496 0 0 0 0 84.992h43.008A42.496 42.496 0 0 0 1024 512zM85.504 469.504a42.496 42.496 0 1 1 0 84.992H42.496a42.496 42.496 0 1 1 0-84.992zM783.36 843.776l30.208 30.208a42.496 42.496 0 0 0 60.416-60.416l-30.208-30.208a42.496 42.496 0 0 0-60.416 60.416zM240.64 240.64a43.52 43.52 0 0 1-60.416 0l-30.208-30.208a42.496 42.496 0 0 1 60.416-60.416l30.208 30.208a43.52 43.52 0 0 1 0 60.416zM150.016 813.568a42.496 42.496 0 0 0 60.416 60.416l30.208-30.208a42.496 42.496 0 1 0-60.416-60.416zM843.776 240.64a42.496 42.496 0 0 1-60.416-60.416l30.208-30.208a42.496 42.496 0 0 1 60.416 60.416z" fill="#1478F0" p-id="21794"></path><path d="M578.56 177.152a341.504 341.504 0 1 0 268.288 267.776 341.504 341.504 0 0 0-268.288-267.776zM472.064 764.928A256 256 0 0 1 409.6 277.504 280.064 280.064 0 0 0 682.496 563.2a291.84 291.84 0 0 0 82.432-11.776 256 256 0 0 1-292.864 213.504z" fill="#1478F0" p-id="21795"></path></svg>
"""),
                  title: Text('主题跟随系统'),
                ),
                // ignore: dead_code
                if (false) SettingsTile.navigation(
                  leading: Icon(Icons.add_box),
                  // TODO(d1y): impl this
                  title: Text('解析线路管理'),
                  onPressed: (cx) {
                    EasyLoading.dismiss();
                    boop.selection();
                    Get.to(() => const ParseVipManagePageView());
                  },
                  value: SimpleTag(text: parseVipListWithText),
                ),
                SettingsTile.navigation(
                  // leading: Icon(Icons.video_settings),
                  leading: leadingIcon(r"""
<svg t="1758541109492" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="47257" width="200" height="200"><path d="M879.488423 92.01323c80.158765 0 145.076075 64.91731 145.076075 145.076075v550.385888c0 80.158765-64.91731 145.076075-145.076075 145.076075H145.076075C64.91731 931.98677 0 867.06946 0 786.910695V237.089305c0-80.158765 64.91731-145.076075 145.076075-145.076075h734.412348z m76.207277 284.507167H68.3043v410.954796c0 41.772878 33.305402 75.642778 75.07828 76.207277H878.923925c41.772878 0 75.642778-33.305402 76.207277-75.07828v-1.128997l0.564498-410.954796zM441.437707 461.759647c3.951488 0 7.338479 1.128997 10.725468 2.822492l205.477398 122.496141c10.16097 6.209482 13.54796 18.628445 7.338479 28.789416-1.693495 2.822492-4.515987 5.644983-7.338479 7.338478L452.163175 745.137817c-10.16097 6.209482-23.144432 2.822492-28.789415-7.338479-1.693495-3.38699-2.822492-6.77398-2.822492-10.725468V482.646086c0-11.289967 9.596472-20.886439 20.886439-20.886439zM68.3043 235.39581V307.651599h101.609702L75.642778 204.9129c-4.515987 9.596472-6.77398 20.32194-7.338478 30.48291z m811.184123-75.07828h-95.964718L910.535832 304.829107c0.564498 1.128997 1.693495 1.693495 2.257994 2.822492h43.466372V237.089305c0-41.772878-33.305402-75.642778-75.07828-76.207276l-1.693495-0.564499z m-187.413451 0h-125.318632l125.318632 145.076075c0.564498 0.564498 1.128997 1.693495 1.693495 2.257994h127.576627l-129.270122-147.334069z m-216.202866 0H353.375965l125.318633 145.076075c0.564498 0.564498 1.128997 1.693495 1.693495 2.257994h123.060639c0 0.564498-127.576626-147.334068-127.576626-147.334069z m-212.815877 0H145.076075c-5.080485 0-10.16097 0.564498-15.241455 1.693495l132.092613 143.947079 1.693495 1.693495h127.576626L263.056229 160.31753z" p-id="47258"></path></svg>
"""),
                  title: Text('视频源管理'),
                  onPressed: (cx) {
                    EasyLoading.dismiss();
                    boop.selection();
                    handleSourceHelp();
                  },
                  value: SimpleTag(text: mirrorLengthWithText),
                ),
                SettingsTile(
                  leading: Icon(CupertinoIcons.macwindow),
                  title: Text("播放器内核"),
                  onPressed: (cx) {
                    final RenderBox renderBox =
                        kVideoKernelBtnKey.currentContext!.findRenderObject()
                            as RenderBox;
                    final Offset btnPosition =
                        renderBox.localToGlobal(Offset.zero);
                    final Size btnSize = renderBox.size;
                    final double targetHeight = btnSize.height;
                    final Rect targetRect = Rect.fromLTWH(
                      btnPosition.dx - 6,
                      btnPosition.dy + 6,
                      btnSize.width,
                      targetHeight,
                    );
                    boop.selection();
                    showPullDownMenu(
                      context: cx,
                      items: _buildVideoKernel(),
                      position: targetRect,
                    );
                  },
                  trailing: PullDownButton(
                    key: kVideoKernelBtnKey,
                    menuOffset: 9,
                    itemBuilder: (cx) {
                      return _buildVideoKernel();
                    },
                    buttonBuilder: (cx, showMenu) {
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          EasyLoading.dismiss();
                          boop.selection();
                          showMenu();
                        },
                        child: Text(_videoKernel.name),
                      );
                    },
                  ),
                ),
                SettingsTile.switchTile(
                  initialValue: _hapticFeedback,
                  onToggle: (flag) {
                    hapticFeedback = flag;
                  },
                  onPressed: (_) {
                    hapticFeedback = !hapticFeedback;
                  },
                  leading: leadingIcon(r"""
<svg t="1758088888195" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="6051" width="200" height="200"><path d="M104.732875 358.909911a83.272497 83.272497 0 0 0 0-74.579357L67.832442 210.425889A35.714533 35.714533 0 1 0 3.9184 242.318036l37.030182 73.956564a12.040648 12.040648 0 0 1 0 10.665315L14.557766 379.56585a83.272497 83.272497 0 0 0 0 74.579357l26.338917 52.625934a12.040648 12.040648 0 0 1 0 10.665315L14.557766 570.062391a83.272497 83.272497 0 0 0 0 74.579357l26.338917 52.625934a12.040648 12.040648 0 0 1 0 10.665315l-37.030182 73.956565a35.743078 35.743078 0 1 0 63.965941 31.918096l36.952333-73.930615a83.272497 83.272497 0 0 0 0-74.579357l-26.287018-52.599984a12.092547 12.092547 0 0 1 0-10.691265l26.287018-52.599985a83.272497 83.272497 0 0 0 0-74.579357l-26.338917-52.625934a12.040648 12.040648 0 0 1 0-10.665315zM631.121969 809.629761h-238.114189a35.706748 35.706748 0 1 0 0 71.413497h238.114189a35.706748 35.706748 0 0 0 0-71.413497zM1020.185398 781.889562l-36.952332-73.956565a11.88495 11.88495 0 0 1 0-10.665315l26.338916-52.625934a83.272497 83.272497 0 0 0 0-74.579357l-26.338916-52.625935a11.88495 11.88495 0 0 1 0-10.665315l26.338916-52.651884a83.272497 83.272497 0 0 0 0-74.579357l-26.338916-52.574035a11.88495 11.88495 0 0 1 0-10.665315l36.952332-73.982514a35.714533 35.714533 0 1 0-63.914041-31.892147l-36.952333 73.904665a83.428195 83.428195 0 0 0 0 74.579357l26.338917 52.625935a11.88495 11.88495 0 0 1 0 10.665315l-26.338917 52.677833a83.428195 83.428195 0 0 0 0 74.579357l26.338917 52.574035a11.936849 11.936849 0 0 1 0 10.691265l-26.338917 52.599985a83.428195 83.428195 0 0 0 0 74.579357l36.952333 73.930615a35.732698 35.732698 0 1 0 63.914041-31.944046z" p-id="6052"></path><path d="M828.858468 52.392387c-28.544639-28.544639-64.87418-41.000481-107.639239-46.709409-41.285928-5.682978-93.782114-5.682978-158.91579-5.682978h-100.477129c-65.107727 0-117.629862 0-158.863891 5.579179-42.868858 5.760827-79.016751 18.16477-107.639239 46.70941s-41.052381 64.87418-46.709409 107.639238c-5.52728 41.389727-5.52728 93.911862-5.527281 159.019589V705.156382c0 65.107727 0 117.629862 5.57918 158.915791 5.760827 42.868858 18.16477 78.964851 46.709409 107.639238s64.87418 40.948582 107.639239 46.70941c41.285928 5.52728 93.808064 5.52728 158.91579 5.52728h100.47713c65.107727 0 117.629862 0 158.91579-5.52728 42.868858-5.812726 78.964851-18.16477 107.639239-46.70941s41.000481-64.87418 46.709409-107.639238c5.52728-41.285928 5.52728-93.808064 5.52728-158.915791V318.947416c0-65.107727 0-117.629862-5.52728-158.91579-5.864626-42.868858-18.16477-78.964851-46.813208-107.639239z m-19.150858 650.143078c0 68.351436 0 116.020983-4.904488 151.987228-4.72284 34.980158-13.286232 53.482274-26.442716 66.664707s-31.710499 21.771775-66.664706 26.468665c-35.966245 4.826639-83.635792 4.904488-152.013178 4.904488h-95.235296c-68.351436 0-116.020983 0-151.961278-4.904488-34.980158-4.696891-53.482274-13.286232-66.690656-26.468665s-21.771775-31.684549-26.468666-66.612807c-4.800689-36.018144-4.904488-83.687692-4.904488-152.039128V321.568333c0-68.377385 0-116.098832 4.904488-151.961278 4.696891-35.006107 13.286232-53.482274 26.468666-66.664707s31.710499-21.771775 66.638757-26.494615c35.992195-4.800689 83.661742-4.904488 152.013177-4.904488h95.235296c68.377385 0 116.046932 0 152.013178 4.904488 34.954208 4.72284 53.430374 13.286232 66.612807 26.494615s21.771775 31.6586 26.494615 66.612808c4.852589 35.966245 4.904488 83.661742 4.904488 152.013177z" p-id="6053"></path></svg>
"""),
                  title: Text("震动反馈"),
                ),
                SettingsTile.switchTile(
                  onToggle: updateNSFW,
                  onPressed: (cx) {
                    boop.selection();
                    updateNSFW(!showNSFW);
                  },
                  initialValue: home.isNsfw,
                  leading: leadingIcon(r"""
<svg t="1757687096526" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="7270" width="200" height="200"><path d="M624.298042 931.498418a80.895919 80.895919 0 0 1-58.026608 24.234642h-108.543892a80.895919 80.895919 0 0 1-58.026608-24.234642 34.133299 34.133299 0 0 0-48.469285 48.469285A150.186516 150.186516 0 0 0 457.727542 1023.999659h108.543892a150.869182 150.869182 0 0 0 106.495893-44.031956 34.133299 34.133299 0 0 0-48.469285-48.469285zM989.865677 477.866871h-76.799923L798.036535 74.411275A102.399898 102.399898 0 0 0 699.391301 0.000683h-64.170603a102.399898 102.399898 0 0 0-57.00261 17.066649l-47.103952 31.743969a34.133299 34.133299 0 0 1-37.887963 0L445.780888 17.067332a102.399898 102.399898 0 0 0-57.00261-17.066649H324.607675a102.399898 102.399898 0 0 0-98.645234 74.410592L110.933222 477.866871H34.133299a34.133299 34.133299 0 0 0 0 68.266599h955.732378a34.133299 34.133299 0 0 0 0-68.266599zM291.839708 93.184589a34.133299 34.133299 0 0 1 34.133299-24.917308h64.170603a34.133299 34.133299 0 0 1 19.114647 5.802661l47.445286 31.402635a102.399898 102.399898 0 0 0 113.322554 0l47.445286-31.402635a34.133299 34.133299 0 0 1 17.749315-5.802661h64.170603a34.133299 34.133299 0 0 1 34.133299 24.575975L803.15653 341.333675H220.842446zM181.930485 477.866871l19.45598-68.266598h621.226046l19.45598 68.266598zM887.465779 648.533367h-3.41333a91.477242 91.477242 0 0 0-89.087911-68.266598h-156.33051a91.818575 91.818575 0 0 0-88.746578 68.266598h-75.775924a91.818575 91.818575 0 0 0-88.746578-68.266598H229.034438a91.135909 91.135909 0 0 0-88.746578 68.266598H136.533197a34.133299 34.133299 0 0 0 0 68.266599v44.031956A92.501241 92.501241 0 0 0 229.034438 853.333163h115.370551a92.501241 92.501241 0 0 0 76.799923-41.301292L462.506204 750.933265a86.015914 86.015914 0 0 0 13.311987-34.133299h72.362594a81.919918 81.919918 0 0 0 13.65332 34.133299l40.959959 61.781272A91.818575 91.818575 0 0 0 679.593987 853.333163h115.370551A92.501241 92.501241 0 0 0 887.465779 760.831922V716.799966a34.133299 34.133299 0 0 0 0-68.266599z m-477.866189 50.517283a24.575975 24.575975 0 0 1-4.095996 13.65332l-40.959959 61.439939a24.917308 24.917308 0 0 1-20.138646 10.922655H229.034438a24.234642 24.234642 0 0 1-24.234643-24.234642v-88.063912a24.575975 24.575975 0 0 1 24.234643-24.234643h156.33051a24.234642 24.234642 0 0 1 24.234642 24.234643z m409.599591 61.781272a24.234642 24.234642 0 0 1-24.234643 24.234642h-115.370551a24.234642 24.234642 0 0 1-19.797313-10.581322l-41.301292-62.122605a22.86931 22.86931 0 0 1-4.095996-13.311987v-26.28264a24.234642 24.234642 0 0 1 24.234642-24.234643h156.33051a24.575975 24.575975 0 0 1 24.234643 24.234643z" fill="#0182DF" p-id="7271"></path></svg>
"""),
                  title: Text('绅士模式'),
                ),
              ],
            ),
            SettingsSection(
              title: Text('其他设置'),
              tiles: <AbstractSettingsTile>[
                SettingsTile.navigation(
                  // leading: Icon(CupertinoIcons.refresh_circled_solid),
                  leading: leadingIcon(r"""
<svg t="1758539785230" class="icon" viewBox="0 0 1097 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="6521" width="200" height="200"><path d="M533.796571 0a512.585143 512.585143 0 0 1 512 512 512.585143 512.585143 0 0 1-512 512 512.585143 512.585143 0 0 1-512-512 512.585143 512.585143 0 0 1 512-512z m249.929143 509.366857h-0.731428c-22.747429 0-41.179429 17.261714-41.179429 38.692572l-0.146286 32.256c-16.384 93.184-102.4 164.205714-205.604571 163.84a214.893714 214.893714 0 0 1-95.524571-22.747429l35.328-23.990857c25.746286-17.554286 18.724571-55.296-11.702858-63.414857L290.377143 587.776c-24.137143-6.363429-48.128 10.752-48.128 34.377143l-0.219429 163.986286c-0.073143 29.037714 34.816 46.006857 59.904 29.037714l65.170286-44.178286c49.737143 33.645714 108.544 51.638857 168.594286 51.638857 145.554286 0.438857 266.386286-99.986286 288.402285-231.570285a34.377143 34.377143 0 0 0 0-10.532572h0.512v-32.182857c0.146286-21.430857-18.285714-38.912-40.96-38.985143zM531.748571 194.633143C386.267429 194.267429 265.362286 294.765714 243.565714 426.203429a35.254857 35.254857 0 0 0 0 10.605714H242.834286v32.256a40.009143 40.009143 0 0 0 40.96 38.838857h0.731428c21.942857 0.658286 40.374857-16.603429 41.179429-38.619429l0.146286-32.329142c16.384-93.037714 102.4-164.059429 205.604571-163.84 33.206857 0.146286 65.828571 8.045714 95.524571 22.893714l-35.401142 23.990857c-25.819429 17.408-18.724571 55.222857 11.776 63.414857l173.714285 46.08c24.137143 6.509714 48.054857-10.532571 48.054857-34.377143l0.292572-163.84c0-29.110857-34.816-46.08-59.977143-29.110857l-65.097143 44.105143A301.129143 301.129143 0 0 0 531.748571 194.56z" fill="#536076" p-id="6522"></path></svg>
"""),
                  title: Text('应用更新'),
                  onPressed: (cx) {
                    boop.selection();
                    showCupertinoModalBottomSheet(
                      context: cx,
                      builder: (_) => AutoUpdate(),
                    );
                  },
                ),
                // ignore: dead_code
                if (false) SettingsTile.navigation(
                  leading: Icon(CupertinoIcons.arrow_down_right_square_fill),
                  title: Text('视频源帮助'),
                  onPressed: (cx) {
                    boop.selection();
                    Get.to(() => const SourceHelpTable());
                  },
                ),
                SettingsTile.navigation(
                  // leading: Icon(CupertinoIcons.clear_thick_circled),
                  leading: leadingIcon(r"""
<svg t="1758539890582" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="7854" width="200" height="200"><path d="M279.779556 206.648889a57.571556 57.571556 0 1 1 57.571555 57.315555 56.888889 56.888889 0 0 1-57.571555-57.315555z m292.736 747.918222c0 0.967111-1.948444 1.948444-2.929778 1.948445l-97.578667-58.311112a3.555556 3.555556 0 0 1-0.995555-2.915555c8.803556-19.427556 97.592889-202.993778 87.836444-193.28a1243.022222 1243.022222 0 0 0-116.124444 139.861333l-26.339556 35.939556s-102.4-68.977778-134.656-111.701334c0-0.967111-0.995556-0.967111 0-1.934222 20.48-25.258667 129.777778-166.087111 129.777778-166.087111l-184.433778 110.734222h-2.929778c-8.789333-9.713778-70.257778-77.710222-88.789333-109.752889v-1.948444c17.564444-14.563556 117.091556-98.133333 117.091555-98.133333l-140.515555 49.536a3.598222 3.598222 0 0 1-2.929778-0.967111l-51.726222-97.137778a1.863111 1.863111 0 0 1 0.981333-2.915556c24.405333-4.835556 230.286222-47.573333 330.794667-116.622222 2.460444-1.692444 5.831111-1.28 7.808 0.981333l287.857778 286.535111c2.261333 1.962667 2.673778 5.319111 0.981333 7.779556a894.904889 894.904889 0 0 0-113.208889 328.291556l0.028445 0.099555z m199.111111-115.584a72.206222 72.206222 0 1 1-72.206223-71.879111 71.879111 71.879111 0 0 1 72.206223 71.879111z m55.608889-36.977778a38.855111 38.855111 0 1 1 38.926222-38.727111 39.054222 39.054222 0 0 1-39.025778 38.855111l0.113778-0.142222z m119.992888-630.371555L765.724444 353.251556c0 2.929778-0.995556 3.896889-0.995555 6.812444 41.002667 69.930667 40.021333 150.556444-19.498667 212.721778a4.736 4.736 0 0 1-6.826666 0L450.56 285.283556a4.664889 4.664889 0 0 1 0-6.798223c62.435556-59.249778 143.445333-59.249778 213.703111-19.427555 2.304 0.099556 4.622222-0.241778 6.826667-0.967111l182.471111-180.622223a66.432 66.432 0 1 1 93.667555 94.151112z" fill="#323233" p-id="7855"></path></svg>
"""),
                  title: Text('清除缓存'),
                  onPressed: handleCleanCacheBefore,
                ),
                SettingsTile.navigation(
                  leading: leadingIcon(kGithubIconSvg),
                  title: Text('开源协议'),
                  onPressed: (cx) {
                    boop.selection();
                    showCupertinoModalBottomSheet(
                      context: cx,
                      backgroundColor: Colors.transparent,
                      transitionBackgroundColor: Colors.transparent,
                      builder: (_) => SizedBox(
                        width: double.infinity,
                        height: Get.height * .72,
                        child: cupertinoLicensePage,
                      ),
                    );
                  },
                ),
                SettingsTile.navigation(
                  leading: SvgPicture.string(
                    r"""
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 256 256"><defs><linearGradient id="IconifyId19941a896f9bb1d3b1" x1="50%" x2="50%" y1="0%" y2="100%"><stop offset="0%" stop-color="#2AABEE"/><stop offset="100%" stop-color="#229ED9"/></linearGradient></defs><path fill="url(#IconifyId19941a896f9bb1d3b1)" d="M128 0C94.06 0 61.48 13.494 37.5 37.49A128.04 128.04 0 0 0 0 128c0 33.934 13.5 66.514 37.5 90.51C61.48 242.506 94.06 256 128 256s66.52-13.494 90.5-37.49c24-23.996 37.5-56.576 37.5-90.51s-13.5-66.514-37.5-90.51C194.52 13.494 161.94 0 128 0"/><path fill="#FFF" d="M57.94 126.648q55.98-24.384 74.64-32.152c35.56-14.786 42.94-17.354 47.76-17.441c1.06-.017 3.42.245 4.96 1.49c1.28 1.05 1.64 2.47 1.82 3.467c.16.996.38 3.266.2 5.038c-1.92 20.24-10.26 69.356-14.5 92.026c-1.78 9.592-5.32 12.808-8.74 13.122c-7.44.684-13.08-4.912-20.28-9.63c-11.26-7.386-17.62-11.982-28.56-19.188c-12.64-8.328-4.44-12.906 2.76-20.386c1.88-1.958 34.64-31.748 35.26-34.45c.08-.338.16-1.598-.6-2.262c-.74-.666-1.84-.438-2.64-.258c-1.14.256-19.12 12.152-54 35.686c-5.1 3.508-9.72 5.218-13.88 5.128c-4.56-.098-13.36-2.584-19.9-4.708c-8-2.606-14.38-3.984-13.82-8.41c.28-2.304 3.46-4.662 9.52-7.072"/></svg>
""",
                    width: 24,
                    height: 24,
                  ),
                  title: Text('小猫交流群'),
                  onPressed: (cx) {
                    boop.selection();
                    kTelegramGroup.openURL();
                  },
                ),
                Copyright(),
                BottomNavigationBarPlaceholder(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class BottomNavigationBarPlaceholder extends AbstractSettingsTile {
  const BottomNavigationBarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: kDefaultAppBottomBarHeight + 24);
  }
}

class Copyright extends AbstractSettingsTile {
  const Copyright({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = SettingsTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.themeData.settingsSectionBackground,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          "$kGithubRepo/tree/$gitCommit".openURL();
        },
        child: Builder(builder: (context) {
          var firstWriteYear = '2020';
          String currentYearString = DateTime.now().year.toString();
          var text = "© 小猫影视 ";
          text += "$firstWriteYear-$currentYearString ";
          text += "$gitTag($gitCommit)";
          return HoverCursor(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                text,
                // textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: (Get.isDarkMode ? Colors.white : Colors.black)
                      .withValues(alpha: .42),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SimpleTag extends StatelessWidget {
  const SimpleTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (context.isDarkMode ? Colors.white : Colors.black)
              .withValues(alpha: .42),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}
