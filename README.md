> 快上我[博客](https://qsctech-sange.github.io)，看更多好康的东西！

# 《投资者情绪与债券风险溢价》SAS 复现

这是一篇论文《投资者情绪与债券风险溢价》的复现，使用SAS语言。

# 论文

在仓库里，点击`Laborda and Olmo 2014 .pdf`即可阅读。论文的内容是讨论投资者情绪与债券风险溢价的关系，简单讲就是利用投资者情绪的数据，宏观经济数据和债券风险溢价数据作回归。

# 数据

所有的数据都在`sentiment`文件夹内。

# 代码

即`investor-sentiment.sas`文件。

注意使用代码运行的时候先修改第一行的数据路径为你保存数据的路径。

# 结果

最后的结果是在`sentiment`文件夹生成一个`rx_predict.csv`，我也将我跑出来的结果放在了仓库根目录里，如果两者相同的话，说明跑成功了。中间的回归过程的结果太长了，可以参阅仓库里的`sas-result.html`或者点[这里](https://qsctech-sange.github.io/sas-result)。

这里简单挑一个回归放一下中间结果。

![img](http://pwb80dtf4.bkt.clouddn.com/SAS-result.webp)