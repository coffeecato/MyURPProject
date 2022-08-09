# Unity URP 练习项目  
## 创建这个工程的背景
接触Unity shader也有几年的时间，《Unity shader入门精要》翻了几遍，catlikecoding大佬的Rendering系列及Custom SRP系列也~~学习~~（抄写）了一遍。在遇到新的需求时有时仍然会遇到知识点盲区或者无法下手的情况。归根到底首先是基础打的不牢，GPU流水线的各个阶段，尤其是矩阵的变换部分（先前每次遇到时都会选择性跳过，感觉对于当下的工作并没有立竿见影的效果，太急功近利了）。再次，就是再前面的基础上遇到一些稍微复杂的技术，会无法理解。  
比如深度纹理的部分，什么时候是NDC space, View space？ 深度如何采样？何时需要考虑Reverse-Z, Flip-Y?  
比如阴影，什么是屏幕空间阴影？  
比如反射，什么是屏幕空间反射？  
等等，坑先挖到这里。

## 目录
填坑开始，深度纹理对于一些~~复杂~~（高级）的渲染技术来说是基础，搞不清楚原理，往后只能做个代码的搬运工，所以还是需要花大力气攻克的。  
1.深度纹理，主要参考了https://blog.csdn.net/puppet_master/article/details/77489948 这篇博客，并在URP Render pipeline下实现其中的shader.  
2.体积渲染，主要参考了https://zhuanlan.zhihu.com/p/248406797    
3.占坑，深入研究Bloom    
4.占坑，水体渲染     



## 学习的过程中顺便记录built-in pipeline与URP pipeline的区别:  
1.built-in涉及后处理的demo中都会通过OnRenderImage(), URP pipeline 中需要自己实现（我是通过Render Feature实现）；  
2.built-in的扭曲在URP pipeline下无法工作，主要原因在于URP 没有Grab Pass，需要自己实现（挖个坑，也是通过Render Feature实现）；


