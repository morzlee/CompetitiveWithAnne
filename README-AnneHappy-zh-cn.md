# **AnneHappy 插件带上对抗插件包**
* 为了保持插件包结构和上游一样方便同步，这个插件包将不会带有nav修改文件和跳舞插件的模型与声音，AnneHappy的Nav修改文件请到我的[anne项目](https://github.com/fantasylidong/anne)中下载

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
* AnneHappy模式猴子有可能会将生还者传送到虚空【重要问题】，有临时修复，会在0.1s后将虚空的生还者传送回来，如果你找到问题是怎么发生的，请反馈一下，谢谢
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
- disabled/specrate.smx 旁观30tick插件，更改后4人旁观数以内，30w积分的玩家也能100tick旁观，超过4人旁观，除管理员外其他旁观玩家一律30tick
- extendd/veterans.smx 时长检测插件，部分依赖于l4d_stats.smx插件的时长信息，能够自定义想玩游戏玩家的时长限制，不满足时长的，只能旁观，join.smx插件依赖这个插件提供是否是steamm组成员的信息
- extend/join.smx 玩家加入离开提示，换队作用，motd展示功能（不是组员会有提示，需要veterans插件作为前置）

## **Issue 发起说明**
请先阅读完README-AnneHappy-zh-cn.md后再发起任何issue
发起issue请进来仔细描述问题，最好能提供错误的log和怎么复现的，拒绝无效Issue
	
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

**注意事项:** 如果你的作品被使用了，而我却忘了归功于你，我真诚地向你道歉。 
我已经尽力将名单上的每个人都包括在内，只要创建一个问题，并说出你所制作/贡献的插件/扩展，我就会确保适当地记入你的名字。
