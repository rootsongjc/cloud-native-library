---
linktitle: 第 7 章：WebAssembly 表
summary: WebAssembly 表。
weight: 8
icon: book-reader
icon_pack: fas
draft: false
title: WebAssembly 表
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

餐桌是分享想法和故事的一个很好的隐喻。与他人一起吃饭总是比自己一个人吃饭更有趣。如果你把一群来自各行各业的人聚集在一起，你可能有谈不完的话题。没有人拥有所有的故事。一些参与者可能分享相同故事的某些方面。其他人可能有他们自己的版本。然而，为了发挥作用，确实必须有一定的礼仪、克制，并愿意接受其他参与者提供的东西。那些行为不端、喋喋不休或相互踩线的客人会毁了大家的晚餐。

表是 WebAssembly 的另一个特点，使得它成为一个现代软件系统，其功能依赖将由额外的模块来满足。与静态链接库相比，它提供了相当于动态共享库的能力。不是每个模块都需要提供它所需要的一切来完成其工作。这将使效率低的可怕。相反，它是根据一些其他模块在运行时满足需求的承诺来编写的。这在 C 和 C++ 世界中被称为动态链接。很明显，我的餐桌论只是对表（Table）这个词的玩味，但就像在吃饭时需要有一些协调来分享想法一样，我们需要在库之间分享行为。让我们更仔细地探讨这个想法，然后看看 WebAssembly 如何支持它。

## 静态链接与动态链接

任何在 Twitter 上关注我的人都知道我妻子是一个多么了不起的厨师。她来自一个伟大的厨师家庭，并有机会向大量慷慨的导师学习。人们经常看到我发布的关于她制作的烹饪艺术的帖子，并向我索取食谱。这通常不像发送一个链接那么容易，因为她经常把来自多个来源的想法结合起来，然后把她自己的想法放在上面。

在我们家，她可以依靠她所积累的食谱库。她可以说，"用那本书里的酱汁做这个。用另一本书中描述的技术准备牛肉。在牛肉达到你想要的熟度后，加入这些我认为会让它变得更好的额外成分"。

在我们家，她可以参考已知来源的步骤和配料表，并以她的额外步骤修正过程。但是当她想把菜谱交给别人时，她不能依靠他们有这些书。在这种情况下，她将不得不把她的来源中的食谱复制到一个自成一体的新食谱文件中。这时，所有的步骤和成分都会被定义在一个地方，菜谱就可以发给别人了。

这基本上就是静态链接和动态链接的区别。一个典型的程序需要读写文件的内容，打开窗口，收集用户的输入，或在网络上发送消息。这些都是很常见的任务，它们通常可以作为操作系统提供的库中的功能。当你希望使用其中的一个函数时，你会告诉链接器允许运行时链接。否则，它将抱怨缺少符号参考。

在运行时，操作系统将搜索其配置路径，告诉它在哪里可以找到这些共享库。在启动程序之前，它将把库中的功能映射到一个可以动态链接到其余代码的内存位置。
这种做法有很多原因。首先是效率问题。比方说，你有一个名为 `a ()` 的函数被十几个其他程序引用。通过静态链接，每个可执行程序都有自己的副本。程序占用了更多的磁盘空间。它们在运行时的内存足迹也会变大。这不是对空间的有效利用。
如果动态库被加载到一个共享的内存空间，那么我们大概只需要磁盘上一个版本的文件副本。根据你的操作系统的复杂性，你可能也只需要内存中的一个副本。

动态链接的库通常有自己的发布周期。如果你正在使用你一个可执行程序的系统库，你可能会更新你的操作系统并得到一个带有安全问题补丁的新版本的库。只要编号机制正常，并且是向后兼容的，假定你可以通过使用打了补丁的版本来加强你的应用程序的安全性，而不需要做任何其他事情。

请看例 7-1，这是一个独立的函数，没有 `main ()` 函数。它的目的是作为一个库来使用。我们可以把它编译成一个静态库，但现在我们只需创建目标代码，并将我们的 `main ()` 程序与之链接。注意， 这个函数也依赖于 `printf ()`，所以它必须导入 `stdio.h` 头。

例 7-1. 一个有函数调用的库

```c
#include <stdio.h>

void sayHello (char *message) {printf ("% s\n", message);
}
```

在例 7-2 中，你会看到`main ()`函数首先调用`printf ()`，然后再调用我们的函数，该函数也调用`printf ()`。

例 7-2. 一个调用我们的库函数的 `main ()` 方法示例

```c
#include <stdio.h>

extern void sayHello (char *message);

int main () {printf ("Hello, world.\n"); 
  sayHello ("How are you?"); 
  return 0;
}
```

默认情况下，如果你用 clang 编译这两个文件，它将生成一个输出文件。我让它使用默认的名字。当我们运行它时，我们会看到我们所期望的行为。默认情况下，编译器将对系统库使用动态链接，以满足我已经列出的所有需求。

```bash
brian@tweezer ~/g/w/s/ch07> clang main.c library.c brian@tweezer ~/g/w/s/ch07> ls
a.out* library.c main.c
brian@tweezer ~/g/w/s/ch07> ./a.out
Hello, world.
How are you?
```

你可以用 nm 命令验证我们在这里使用了动态链接。首先，我们看到我们的二进制文件提供了`main ()`和`sayHello ()`的定义，但没有`printf ()`。这是从标准库中重复使用的函数：

```bash
brian@tweezer ~/g/w/s/ch07> nm a.out 
0000000100008008 d __dyld_private 
0000000100000000 T __mh_execute_header
0000000100003f10 T _main
                 U _printf
0000000100003f50 T _sayHello
                 U dyld_stub_binder
```

在 Linux 上，你可以看到同样的构建步骤产生了一个带有额外功能的二进制文件。这很自然，因为它是一个不同的操作系统，有不同的运行时和不同的二进制格式。突出的一点是，我们的方法是在二进制文件中提供的，但`printf ()`却没有。

```bash
brian@bbfcfm:~/src/hello$ nm a.out
0000000000404030 B __bss_start
0000000000404030 b completed.8060
0000000000404020 D __data_start
0000000000404020 W data_start
0000000000401080 t deregister_tm_clones
0000000000401070 T _dl_relocate_static_pie
00000000004010f0 t __do_global_dtors_aux
0000000000403e08 d __do_global_dtors_aux_fini_array_entry 0000000000404028 D __dso_handle
0000000000403e10 d _DYNAMIC
0000000000404030 D _edata
0000000000404038 B _end
0000000000401218 T _fini
0000000000401120 t frame_dummy
0000000000403e00 d __frame_dummy_init_array_entry
000000000040216c r __FRAME_END__
0000000000404000 d _GLOBAL_OFFSET_TABLE_
                 w __gmon_start__
0000000000402024 r __GNU_EH_FRAME_HDR
0000000000401000 T _init
0000000000403e08 d __init_array_end
0000000000403e00 d __init_array_start
0000000000402000 R _IO_stdin_used
0000000000401210 T __libc_csu_fini
00000000004011a0 T __libc_csu_init
                 U __libc_start_main@@GLIBC_2.2.5
0000000000401130 T main
                 U printf@@GLIBC_2.2.5
00000000004010b0 t register_tm_clones
0000000000401170 T sayHello
0000000000401040 T _start
0000000000404030 D __TMC_END__
```

otool 命令是另一个可以在 macOS 上使用的命令，它可以显示哪些动态库是成功执行你的二进制文件所需要的。显示的是系统库的 macOS 版本：

```bash
brian@tweezer ~/g/w/s/ch07> otool -L a.out 
a.out:
   /usr/lib/libSystem.B.dylib (compatibility vers 1.0.0, current vers 1292.60.1)
```

otool 在 Linux 上并不存在，但我们可以通过使用 objdump 看到类似的结果。为了节省空间，我把部分输出删除了，但相关部分显示在下面的片段中。正如你所看到的，我们需要`libc.so.6`来满足我们二进制文件的需要。在 Windows 上也会有类似的工具来检查你的 DLL 依赖性。

```bash
brian@bbfcfm:~/src/hello$ objdump -x a.out
    a.out:     file format elf64-x86-64
    a.out
    architecture: i386:x86-64, flags 0x00000112:
    EXEC_P, HAS_SYMS, D_PAGED
    start address 0x0000000000401040
...
Dynamic Section:
  NEEDED        	libc.so.6
  INIT          	0x0000000000401000
  FINI	          0x0000000000401218
  INIT_ARRAY	    0x0000000000403e00
  INIT_ARRAYSZ  	0x0000000000000008
  FINI_ARRAY	    0x0000000000403e08
  FINI_ARRAYSZ  	0x0000000000000008
  HASH	          0x00000000004002e8
  GNU_HASH      	0x0000000000400310
  STRTAB	        0x0000000000400390
  SYMTAB	        0x0000000000400330
  STRSZ         	0x000000000000003f
  SYMENT	        0x0000000000000018
  DEBUG	          0x0000000000000000
  PLTGOT	        0x0000000000404000
  PLTRELSZ	      0x0000000000000018
  PLTREL	        0x0000000000000007
  JMPREL	        0x0000000000400428
  RELA	          0x00000000004003f8
  RELASZ	        0x0000000000000030
  RELAENT	        0x0000000000000018
  VERNEED	        0x00000000004003d8
  VERNEEDNUM    	0x0000000000000001
  VERSYM        	0x00000000004003d0
Version References:
  required from libc.so.6:
    0x09691a75 0x00 02 GLIBC_2.2.5
...
```

WebAssembly 与操作系统显然不是一回事，但它得益于类似的概念。我们的选择是一样的：把所有的函数定义放到一个模块里，这样它就可以独立存在，或者从另一个模块调用行为，以满足我们的需要。考虑到我们要经常通过网络下载 WebAssembly 模块，让它们偏小是可取的。这也会影响到磁盘存储、模块验证、在内存中加载实例等。为此，我们有 Table 实例。

## 在模块中创建表

表实例有一些类似于我们在 [第 4 章](../wasm-memeory/) 中介绍的 Memory 实例的特征。目前每个模块只能有一个，但它可以在模块中定义，也可以通过导入的对象传入。每个模块只有一个实例的限制在未来可能会被取消，但目前我们必须 遵守这一规定。

我们在 WebAssembly 中采用这种结构，而不是仅仅使用 Memory 实例，部分原因是后者可以被模块操纵。如果我们试图进行一次适当的晚餐谈话，我们不希望任何个人参与者改写礼貌的规则。在共享模块上也是如此。如果我们已经加载并验证了一个通过表实例导出函数的模块，我们不希望另一个模块给其他人带来麻烦。因此，你所能做的就是对存储在表中的函数引用进行间接函数调用。目前，函数引用是唯一可以存储在表实例中的东西，但这也有望在未来改变。

在这一点上，我不想把事情搞得太复杂，而是要回到 Wat 中的简单函数定义，以演示创建表实例和导出它们的方法。

在例 7-3 中，我创建了两个函数。`$add` 函数接收两个参数，将它们相加，然后返回结果。`$sub` 函数接收两个参数，用第一个参数减去第二个参数，然后返回结果。到目前为止，正如他们所说，那又怎样呢？这不过是前几章的复习内容。这里的区别在于接下来会发生什么。

例 7-3. 一个导出其表实例的模块

```bash
(module
  (func $add (param $a i32) (param $b i32) (result i32)
      get_local $a
      get_local $b
      i32.add)
(func $sub (param $a i32) (param $b i32) (result i32)
      get_local $a
      get_local $b
      i32.sub)
  (table (export "tbl") anyfunc (elem $add $sub))
)
```

我们引入了一个新的 Wat 关键字 ——table。这定义了一个函数引用的集合。注意内联导出命令。我们将允许我们的主机环境通过`$add`和`$sub`函数调用方法，但不能通过它们的名字。宿主只能通过表的实例来调用行为。Anyfunc 类型目前是这个结构唯一允许的类型，正如我们之前指出的那样。根据 elem 引用中的排序，`$add`将在第 0 个位置，`$sub` 将在第 1 个位置 [^1]。

正如你现在所知道的，我们可以把我们的 Wat 文件变成一个 Wasm 模块，并检查其内容，如下所示。注意表部分、类型部分和导出部分。

```bash
brian@tweezer ~/g/w/s/ch07> wat2wasm math.wat 
brian@tweezer ~/g/w/s/ch07> wasm-objdump -x math.wasm
    math.wasm:      file format wasm 0x1
    Section Details:
    Type [1]:
     - type [0] (i32, i32) -> i32
    Function [2]:
     - func [0] sig=0
     - func [1] sig=0
    Table [1]:
     - table [0] type=funcref initial=2 max=2
    Export [1]:
     - table [0] -> "tbl"
    Elem [1]:
     - segment [0] flags=0 table=0 count=2 - init i32=0
      - elem [0] = func [0]
      - elem [1] = func [1]
    Code [2]:
     - func [0] size=7
     - func [1] size=7
```

例 7-4 中的 JavaScript 实例化了我们的模块，就像我们在之前章节中做的那样。从那里，它从模块的导出部分提取 Table 实例。

例 7-4. 使用一个从 JavaScript 导出的表实例

```html
<!doctype html>

<html>
  <head>
      <title>WASM Table test</title>
      <meta charset="utf-8">
      <script src="utils.js"></script>
      <link rel="icon" href="data:;base64,=">
  </head>

  <body>
    <script>
      var t;

      fetchAndInstantiate ('math.wasm').then (function (instance) {
	  var tbl = instance.exports.tbl;
	  t = tbl;
	  console.log ("3 + 1 =" + tbl.get (0)(3,1));
  	console.log ("3 - 1 =" + tbl.get (1)(3,1));
      });
    </script>
  </body>
</html>
```

在我们获取引用后，我们可以检索到与第 0 个位置相关的函数并调用它。请记住，从`get ()` 调用回来的是一个函数的引用。为了调用它，我们提交第二组括号中的参数，然后将结果打印到控制台。然后我们对第 1 个位置上的函数也这样做。

通过 HTTP 发送 HTML，并打开 JavaScript 控制台。当你的浏览器执行该代码时，它应该如图 7-1 所示。

![图 7-1. 通过表实例调用方法的输出结果](../images/f7-1.png)

表的实例只被定义为有两个引用。如果你试图访问一个超过 `tbl.length` 的位置，就会引起一个异常。

## WebAssembly 中的动态链接

我们的最后一个例子是在 WebAssembly 中使用动态链接。我们将定义两个模块。一个将包含我们预先定义的 `$add` 和 `$sub` 方法。第一个模块在例 7-5 中。与我们之前看到的主要区别是，这个模块从主机中导入了一个表。我们用 elem 指令将算术函数放入这个表中。加法函数被存放在 0 号位置，减法函数被存放在 1 号位置。

例 7-5. 一个动态链接的模块

```bash
(module
  (import "js" "table" (table 2 anyfunc))
  (func $add (param $a i32) (param $b i32) (result i32)
      get_local $a
      get_local $b
      i32.add)
  (func $sub (param $a i32) (param $b i32) (result i32)
      get_local $a
      get_local $b
      i32.sub)
  (elem (i32.const 0) $add)
  (elem (i32.const 1) $sub)
)
```

我们的第二个模块将输出两个函数，myadd 和 mysub。它向其客户宣传加减两个数字的能力。在内部，它将调用导入表实例中的函数引用，我们也从主机的 JavaScript 环境中导入。

我们所宣传的功能的实现见于例 7-6。两个函数都调用了 call_indirect 指令。在前面的章节中，我们看到使用调用指令来调用当前模块中定义的函数。call_indirect 指令通过确定你想调用的表的哪个元素来调用一个函数。

例 7-6. 依赖于动态链接模块的一个模块

```bash
(module
  (import "js" "table" (table 2 anyfunc))
  (type $sig (func (param $a i32) (param $b i32) (result i32)))
  (func (export "myadd") (param $a i32) (param $b i32) (result i32) (call_indirect (type $sig) (get_local $a) (get_local $b) (i32.const 0))
)
  (func (export "mysub") (param $a i32) (param $b i32) (result i32) (call_indirect (type $sig) (get_local $a) (get_local $b) (i32.const 1))
  )
)
```

其中一个会让你眼前一亮的东西是类型指令的使用。这将定义一个函数的签名，以便在 WebAssembly 中提供一定程度的类型安全。我们的想法是，一个导入的表函数应该有你想要调用的签名。

在这种情况下，我们定义了一个函数签名，它接收两个 i32 并返回一个 i32。当我们通过表调用这些方法时，我们表明这是我们所期望的类型。在签名之后，我们将函数的参数推到堆栈中，最后推到表的位置号。对于加法，它的常量值是 0，代表表的第一个位置。对于减法，它将是第二个位置。

我们在例 7-7 中把这一切放在一起。我们做的第一件事是创建一个共享的表实例。这将通过 importObject 传递给两个模块。不同的是，math2.wat 模块将其函数 `$add` 和 `$sub` 分别写在 0 和 1 的位置。mymath.wat 模块在从主机 JavaScript 环境中调用 myadd 和 mysub 时间接地调用了这些位置。作为调用的一部分，它们也将把它们被赋予的参数传递给动态链接的函数。

因为我们处理的是两个模块，所以我们的实例化机制略有不同。我们调用 `Promise.all ()` 方法，而不是等待一个单一的 Promise，该方法会阻止所有的从属 Promise 得到满足。在这种情况下，这意味着两个模块都已加载并准备就绪。

例 7-7. 实例化两个模块并在它们之间建立动态链接

```html
<!DOCTYPE html>
<html>
 <head> 
  <title>WASM Dynamic Linking test</title> 
  <meta charset="utf-8" /> 
  <script src="utils.js"></script> 
  <link rel="icon" href="data:;base64,=" /> 
 </head> 
 <body> 
  <script>
      var importObject = {
	  js: {memory: new WebAssembly.Memory ({ initial: 1}),
	      table: new WebAssembly.Table ({initial:2, element:"anyfunc"})
	  }
      };

      Promise.all ([fetchAndInstantiate ('math2.wasm', importObject),
	        fetchAndInstantiate ('mymath.wasm', importObject)
      ]).then (function (instances) {console.log ("4 + 3 =" + instances [1].exports.myadd (4,3));
    console.log ("4 - 3 =" + instances [1].exports.mysub (4,3));
      });

    </script>  
 </body>
</html>
```

一旦模块都可用，这段代码就用一些参数调用 myadd 和 mysub 方法。注意我们正在选择第二个模块实例，代表我们的行为版本。这是一个数组的实例，而不是一个单一的实例。

在通过 HTTP 提供服务后，浏览器中的结果如图 7-2 所示。一个模块通过共享的 Table 实例间接调用在另一个模块中实现的行为。

![图 7-2. 调用我们的动态链接函数的输出结果](../images/f7-2.png)

至此，我们对 WebAssembly 作为一个平台的主要功能元素的介绍结束了。本书的其余部分将以这些基础知识为基础，向你展示几个例子，说明 WebAssembly 现在是如何被使用的，以及它在未来将如何被使用。这包括一些我们尚未涉及的更高级的功能。

## 注释

[^1]: 基于 0 的集合中的第二个位置。
