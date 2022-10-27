# **AnneHappy 插件带上对抗插件包**
* 这个插件包将不会带有nav修改文件和跳舞插件的模型与声音，如果需要AnneHappy的Nav修改文件请到我的[anne项目](https://github.com/fantasylidong/anne)中下载

## **关于新增模式:**

> **AnneHappy新加模式:**
* **AnneHappy 普通药役模式**
* **Hunters 1vHT模式**
* **AllCharget 牛牛冲刺大赛模式**
* **Witch Party模式** 
* **Alone 单人装逼模式**


---

## **重要内容**
* 其中Anne插件放到了optional/AnneHappy文件夹中，源码位于script/AnneHappy文件夹中
* 其中extend文件夹中的插件为电信服扩展所用，包括帽子、积分和商店娱乐等功能（默认启用）
* 本插件尽量在不影响Zonemod同步上游更新的基础进行更新（方便自己偷懒）
---

## **已知问题:**
* 小刀为TLS更新前的原版小刀
* ~~对抗原生的更换队伍不能用，使用join.smx插件进行换队(!inf !infected 感染 !jg !join 生还 !spec !afk旁观）~~ 已解决

## **无数据库服务器安装问题:**
> 由于我的数据库不会对外放开，所以有些插件你需要删除或者自建数据库[数据库脚本在项目内]
- extend/l4d_stats.smx 积分插件，需要数据库，很多插件也依赖这个插件提供的积分，不过后面经过修改，这些依赖于这个积分插件的插件
也能在无积分插件情况下运行了
- chat-processor.smx 聊天语句处理插件，称号插件的前置插件
- extend/hextags.smx 称号插件 其中自定义称号需要rpg插件， 积分插件相互配合才能使用，无积分的情况下你可以直接去configs/hextags.cfg文件内增加自定义称号
- extend/lilac.smx 会保存检测记录到数据库l4d2_stats数据库
- extend/sbpp_******.smx sourcebans插件，方便进行所有服务器封禁
- extend/rpg.smx 商店插件，会自动检测依赖，没数据库也能用，或者你自己改用原来anne的，问题不大
- extend/chatlog.smx 数据库聊天记录插件
- extend/l4d_hats.smx 插件，最新帽子插件修改版，增加了数据库功能和forward处理，无积分插件也能使用，但是需要自己配置好l4d_hats配置
- extend/l4d2_item_hint.smx 标点插件，禁用了一部分功能，增加了光圈标点的聊天栏提示，也需要积分功能搭配限制，无积分插件也能使用
	
## **感谢人员:**

> **Foundation/Advanced Work:**
* morzlee 本分支创建者及维护者
* Caibiiii 原分支创建者
* HoongDou 原分支创建者

> **Additional Plugins/Extensions:**
* GlowingTree880 特感能力加强的巨大贡献者

> **Competitive Mapping Rework:**
* Derpduck, morzlee 地图修改

> **Testing/Issue Reporting:**
* Too many to list, keep up the great work in reporting issues!

**NOTE:** If your work is being used and I forgot to credit you, my sincere apologies.  
I've done my best to include everyone on the list, simply create an issue and name the plugin/extension you've made/contributed to and I'll make sure to credit you properly.
