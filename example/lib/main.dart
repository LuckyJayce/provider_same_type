import 'dart:collection';

import 'package:flutter/material.dart';

final countKey = ProviderKey<ValueNotifier<int>>();
final countKey2 = ProviderKey<ValueNotifier<int>>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: countKey.provider(
          data: ValueNotifier<int>(0),
          child: countKey2.provider(
            data: ValueNotifier<int>(0),
            child: Builder(builder: (context) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountWidget(),
                    CountWidget2(),
                  ],
                ),
              );
            }),
          )),
    );
  }
}

class CountWidget extends StatelessWidget {
  const CountWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('count:${countKey.watch(context)!.value}'),
        FlatButton(
          color: Colors.blue,
          onPressed: () {
            countKey.read(context)!.value++;
          },
          child: Text('add'),
        ),
      ],
    );
  }
}

class CountWidget2 extends StatelessWidget {
  const CountWidget2({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('count:${countKey2.watch(context)!.value}'),
        FlatButton(
          color: Colors.blue,
          onPressed: () {
            countKey2.read(context)!.value++;
          },
          child: Text('add'),
        ),
      ],
    );
  }
}

// -------------------------- 实现 -------------------------
class ProviderKey<T extends ChangeNotifier> {
  ProviderKey();

  static final Map<Type, InheritedWidgetFactories> typeInhFactories = {};

  InheritedProvider<T> buildInh(T data, Widget child) {
    InheritedWidgetFactories<T>? typeBuilders =
        typeInhFactories[T] as InheritedWidgetFactories<T>?;
    if (typeBuilders == null) {
      typeBuilders = InheritedWidgetFactories<T>();
      typeInhFactories[T] = typeBuilders;
    }
    return typeBuilders.buildInh(this, data, child);
  }

  void dispose() {
    InheritedWidgetFactories<T>? typeBuilders =
        typeInhFactories[T] as InheritedWidgetFactories<T>?;
    if (typeBuilders != null) {
      typeBuilders.dispose(this);
    }
  }

  ChangeNotifierProvider<T> provider({required T data, required Widget child}) {
    return ChangeNotifierProvider<T>(
      providerKey: this,
      data: data,
      child: child,
    );
  }

  T? read(BuildContext context) {
    InheritedWidgetFactories<T>? typeBuilders =
        typeInhFactories[T] as InheritedWidgetFactories<T>?;
    if (typeBuilders == null) {
      return null;
    }
    return typeBuilders.read(this, context);
  }

  T? watch(BuildContext context) {
    InheritedWidgetFactories<T>? typeBuilders =
        typeInhFactories[T] as InheritedWidgetFactories<T>?;
    if (typeBuilders == null) {
      return null;
    }
    return typeBuilders.watch(this, context);
  }
}

///----数据Provider
class InheritedProvider<T> extends InheritedWidget {
  InheritedProvider({
    required this.data,
    required Widget child,
  }) : super(child: child);

  InheritedProvider.task({
    required this.data,
    required Widget child,
  }) : super(child: child);

  final T data;

  @override
  bool updateShouldNotify(InheritedProvider<T> old) {
    //在此简单返回true，则每次更新都会调用依赖其的子孙节点的`didChangeDependencies`。
    return true;
  }
}

///使用StatefulWidget的state 注册ChangeNotifier监听变化，
///重新创建InheritedProvider（随之重新build依赖数据的widget），
///缓存InheritedProvider的child
class ChangeNotifierProvider<T extends ChangeNotifier> extends StatefulWidget {
  ChangeNotifierProvider({
    Key? key,
    required this.providerKey,
    required this.data,
    required this.child,
  });

  final Widget child;
  final T data;
  final ProviderKey<T> providerKey;

  @override
  _ChangeNotifierProviderState<T> createState() =>
      _ChangeNotifierProviderState<T>();
}

class _ChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<ChangeNotifierProvider<T>> {
  void update() {
    //如果数据发生变化（model类调用了notifyListeners），重新构建InheritedProvider
    setState(() {
      print('_ChangeNotifierProviderState setState');
    });
  }

  @override
  void didUpdateWidget(ChangeNotifierProvider<T> oldWidget) {
    //当Provider更新时，如果新旧数据不"=="，则解绑旧数据监听，同时添加新数据监听
    if (widget.data != oldWidget.data) {
      oldWidget.data.removeListener(update);
      widget.data.addListener(update);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    // 给model添加监听器
    widget.data.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    // 移除model的监听器
    widget.data.removeListener(update);
    widget.providerKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.providerKey.buildInh(widget.data, widget.child);
  }
}

class InheritedWidgetFactories<T> {
  static final List<int> indexList = [0, 1, 2, 3, 4];
  Queue<int> unUsedIndex = Queue.of(indexList);
  Queue<int> usedIndex = Queue();
  Map<ProviderKey, int> inhIndexMap = {};

  T? read(ProviderKey providerKey, BuildContext context) {
    int? inhIndex = inhIndexMap[providerKey];
    if (inhIndex == null) {
      return null;
    }
    switch (inhIndex) {
      case 0:
        return readImp<_Inh0<T>>(context);
      case 1:
        return readImp<_Inh1<T>>(context);
      case 2:
        return readImp<_Inh2<T>>(context);
      case 3:
        return readImp<_Inh3<T>>(context);
      case 4:
      default:
        return readImp<_Inh4<T>>(context);
    }
  }

  T? readImp<I extends InheritedProvider<T>>(BuildContext context) {
    return (context.getElementForInheritedWidgetOfExactType<I>()!.widget
            as InheritedProvider<T>)
        .data;
  }

  T? watch(ProviderKey providerKey, BuildContext context) {
    int? inhIndex = inhIndexMap[providerKey];
    if (inhIndex == null) {
      return null;
    }
    switch (inhIndex) {
      case 0:
        return context.dependOnInheritedWidgetOfExactType<_Inh0<T>>()!.data;
      case 1:
        return context.dependOnInheritedWidgetOfExactType<_Inh1<T>>()!.data;
      case 2:
        return context.dependOnInheritedWidgetOfExactType<_Inh2<T>>()!.data;
      case 3:
        return context.dependOnInheritedWidgetOfExactType<_Inh3<T>>()!.data;
      case 4:
      default:
        return context.dependOnInheritedWidgetOfExactType<_Inh4<T>>()!.data;
    }
  }

  InheritedProvider<T> buildInh(ProviderKey providerKey, T data, Widget child) {
    int? inhIndex = inhIndexMap[providerKey];
    if (inhIndex == null) {
      inhIndex = unUsedIndex.removeFirst();
      usedIndex.addLast(inhIndex);
      inhIndexMap[providerKey] = inhIndex;
    }
    switch (inhIndex) {
      case 0:
        return _Inh0(data, child);
      case 1:
        return _Inh1(data, child);
      case 2:
        return _Inh2(data, child);
      case 3:
        return _Inh3(data, child);
      case 4:
      default:
        return _Inh4(data, child);
    }
  }

  void dispose(ProviderKey providerKey) {
    int? factoryIndex = inhIndexMap.remove(providerKey);
    if (factoryIndex != null) {
      unUsedIndex.addLast(factoryIndex);
      usedIndex.remove(factoryIndex);
    }
  }
}

class _Inh0<T> extends InheritedProvider<T> {
  _Inh0(T data, Widget child) : super(data: data, child: child);
}

class _Inh1<T> extends InheritedProvider<T> {
  _Inh1(T data, Widget child) : super(data: data, child: child);
}

class _Inh2<T> extends InheritedProvider<T> {
  _Inh2(T data, Widget child) : super(data: data, child: child);
}

class _Inh3<T> extends InheritedProvider<T> {
  _Inh3(T data, Widget child) : super(data: data, child: child);
}

class _Inh4<T> extends InheritedProvider<T> {
  _Inh4(T data, Widget child) : super(data: data, child: child);
}
