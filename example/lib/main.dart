import 'dart:collection';

import 'package:flutter/material.dart';

const countKey = ProviderKey<ValueNotifier<int>>();
const countKey2 = ProviderKey<ValueNotifier<int>>();

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
class TypeBuilders {
  Map<ProviderKey, InheritedProviderBuilder> builders = {};
  Queue<int> unUsedIns = Queue.of([0, 1, 2, 3, 4]);
  Queue<int> usedIns = Queue();

  InheritedProviderBuilder<T>? get<T extends ChangeNotifier>(
      ProviderKey<T> providerKey) {
    return builders[providerKey] as InheritedProviderBuilder<T>?;
  }

  InheritedProviderBuilder<T> getOrCreate<T extends ChangeNotifier>(
      ProviderKey<T> providerKey) {
    InheritedProviderBuilder<T>? builder =
        builders[providerKey] as InheritedProviderBuilder<T>?;
    if (builder == null) {
      int index = unUsedIns.removeLast();
      usedIns.addLast(index);
      builder = InheritedProviderBuilder(index);
      builders[providerKey] = builder;
    }
    return builder;
  }

  void dispose<T extends ChangeNotifier>(ProviderKey<T> providerKey) {
    InheritedProviderBuilder? builder = builders.remove(providerKey);
    if (builder != null) {
      unUsedIns.addLast(builder.index);
      usedIns.remove(builder.index);
    }
  }
}

class ProviderKey<T extends ChangeNotifier> {
  const ProviderKey();

  static final Map<Type, TypeBuilders> typeProviderBuilders = {};

  InheritedProviderBuilder<T>? getInheritedProviderBuilder() {
    TypeBuilders? typeBuilders = typeProviderBuilders[T];
    if (typeBuilders == null) {
      return null;
    }
    return typeBuilders.get<T>(this);
  }

  InheritedProviderBuilder<T> getOrCreateInheritedProviderBuilder() {
    TypeBuilders? typeBuilders = typeProviderBuilders[T];
    if (typeBuilders == null) {
      typeBuilders = TypeBuilders();
      typeProviderBuilders[T] = typeBuilders;
    }
    return typeBuilders.getOrCreate<T>(this);
  }

  void dispose() {
    TypeBuilders? typeBuilders = typeProviderBuilders[T];
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
    return getInheritedProviderBuilder()?.read<T>(context);
  }

  T? watch(BuildContext context) {
    return getInheritedProviderBuilder()?.watch<T>(context);
  }

  @override
  String toString() {
    return name;
  }
}

///----数据Provider
class InheritedProvider<T> extends InheritedWidget {
  InheritedProvider({
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
    InheritedProviderBuilder<T> builder =
        widget.providerKey.getOrCreateInheritedProviderBuilder();
    return builder.build(widget.data, widget.child);
  }
}

class InheritedProviderBuilder<T> {
  int index;

  InheritedProviderBuilder(this.index);

  T watch<T>(BuildContext context) {
    switch (index) {
      case 0:
        return context.dependOnInheritedWidgetOfExactType<InA<T>>()!.data;
      case 1:
        return context.dependOnInheritedWidgetOfExactType<InB<T>>()!.data;
      case 2:
        return context.dependOnInheritedWidgetOfExactType<InC<T>>()!.data;
      case 3:
        return context.dependOnInheritedWidgetOfExactType<InD<T>>()!.data;
      case 4:
      default:
        return context.dependOnInheritedWidgetOfExactType<InE<T>>()!.data;
    }
  }

  T watchIm<E extends InheritedProvider<T>, T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<E>()!.data;
  }

  T read<T>(BuildContext context) {
    print('read index:$index');
    switch (index) {
      case 0:
        return (context
                .getElementForInheritedWidgetOfExactType<InA<T>>()!
                .widget as InA<T>)
            .data;
      case 1:
        return (context
                .getElementForInheritedWidgetOfExactType<InB<T>>()!
                .widget as InB<T>)
            .data;
      case 2:
        return (context
                .getElementForInheritedWidgetOfExactType<InC<T>>()!
                .widget as InC<T>)
            .data;
      case 3:
        return (context
                .getElementForInheritedWidgetOfExactType<InD<T>>()!
                .widget as InD<T>)
            .data;
      case 4:
      default:
        return (context
                .getElementForInheritedWidgetOfExactType<InE<T>>()!
                .widget as InE<T>)
            .data;
    }
  }

  InheritedProvider<T> build(T data, Widget child) {
    InheritedProvider<T> inP;
    switch (index) {
      case 0:
        inP = InA<T>(data: data, child: child);
        break;
      case 1:
        inP = InB<T>(data: data, child: child);
        break;
      case 2:
        inP = InC<T>(data: data, child: child);
        break;
      case 3:
        inP = InD<T>(data: data, child: child);
        break;
      case 3:
        inP = InE<T>(data: data, child: child);
        break;
      case 4:
      default:
        inP = InE<T>(data: data, child: child);
        break;
    }
    return inP;
  }

  @override
  String toString() {
    return 'InheritedProviderBuilder{index: $index}';
  }
}

class InA<T> extends InheritedProvider<T> {
  InA({required T data, required Widget child})
      : super(data: data, child: child);
}

class InB<T> extends InheritedProvider<T> {
  InB({required T data, required Widget child})
      : super(data: data, child: child);
}

class InC<T> extends InheritedProvider<T> {
  InC({required T data, required Widget child})
      : super(data: data, child: child);
}

class InD<T> extends InheritedProvider<T> {
  InD({required T data, required Widget child})
      : super(data: data, child: child);
}

class InE<T> extends InheritedProvider<T> {
  InE({required T data, required Widget child})
      : super(data: data, child: child);
}
