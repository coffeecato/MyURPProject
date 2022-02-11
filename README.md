# MyURPProject

Unity URP 练习项目
先从后处理部分入手，第一部分-深度纹理的学习及应用，主要参考了https://blog.csdn.net/puppet_master/article/details/77489948 这篇博客，并在URP Render pipeline下实现其中的shader.

built-in pipeline与URP pipeline的区别如下:

1.built-in涉及后处理的demo中都会通过OnRenderImage(), URP pipeline 中需要自己实现（我是通过Render Feature实现）

2.built-in的扭曲在URP pipeline下无法工作，主要原因在于URP 没有Grab Pass，需要自己实现（挖个坑，也是通过Render Feature实现）

3.还有什么坑要挖还没想好。
